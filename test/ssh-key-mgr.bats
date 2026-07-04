#!/usr/bin/env bats

# Tests for ssh-key-mgr — uses a temporary directory as $HOME so
# the real ~/.ssh is never touched.

bats_require_minimum_version 1.5.0

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/ssh-key-mgr"

setup() {
    # Redirect HOME to a temporary directory so the script initialises
    # its own fresh ~/.ssh tree without touching the real one.
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    unset KEYS_SERVER_URL
    unset SSH_AUTH_SOCK
}

teardown() {
    true
}

# ---------------------------------------------------------------------------
# Dispatcher — no action / help
# ---------------------------------------------------------------------------

@test "no arguments prints error and exits non-zero" {
    run "$SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "No action specified" ]]
}

@test "help action prints usage" {
    run "$SCRIPT" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SSH Key manager" ]]
}

@test "--help flag prints usage" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SSH Key manager" ]]
}

@test "--? flag prints usage" {
    run "$SCRIPT" --?
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SSH Key manager" ]]
}

@test "unknown action exits non-zero" {
    run "$SCRIPT" unknownaction
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown action" ]]
}

# ---------------------------------------------------------------------------
# create
# ---------------------------------------------------------------------------

@test "create without --host exits non-zero" {
    run "$SCRIPT" create --comment "Test"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "create with valid host creates key files and config entry" {
    run "$SCRIPT" create --host testhost.example.com --comment "Test key"
    [ "$status" -eq 0 ]
    [ -f "$HOME/.ssh/id_testhost.example.com" ]
    [ -f "$HOME/.ssh/id_testhost.example.com.pub" ]
    grep -q "Host testhost.example.com" "$HOME/.ssh/config"
}

@test "create for existing host exits non-zero" {
    "$SCRIPT" create --host dup.example.com --comment "First key"
    run "$SCRIPT" create --host dup.example.com --comment "Duplicate key"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Host already has key" ]]
}

@test "create skips key server upload when KEYS_SERVER_URL is unset" {
    run "$SCRIPT" create --host noserver.example.com --comment "No server"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "KEYS_SERVER_URL not set" ]]
}

# ---------------------------------------------------------------------------
# show
# ---------------------------------------------------------------------------

@test "show without --host exits non-zero" {
    run "$SCRIPT" show
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "show for unknown host exits non-zero" {
    run "$SCRIPT" show --host unknown.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Could not find host key" ]]
}

@test "show for existing host prints public key" {
    "$SCRIPT" create --host showhost.example.com --comment "Show test"
    run "$SCRIPT" show --host showhost.example.com
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ssh-ed25519" ]]
}

# ---------------------------------------------------------------------------
# revoke
# ---------------------------------------------------------------------------

@test "revoke without --host exits non-zero" {
    run "$SCRIPT" revoke
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "revoke for unknown host exits non-zero" {
    run "$SCRIPT" revoke --host unknown.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Could not find host key" ]]
}

@test "revoke moves key files to old directory and removes config entry" {
    "$SCRIPT" create --host revoke.example.com --comment "Revoke test"
    run "$SCRIPT" revoke --host revoke.example.com
    [ "$status" -eq 0 ]
    [ ! -f "$HOME/.ssh/id_revoke.example.com" ]
    [ ! -f "$HOME/.ssh/id_revoke.example.com.pub" ]
    [ -f "$HOME/.ssh/old/id_revoke.example.com.revoked" ]
    [ -f "$HOME/.ssh/old/id_revoke.example.com.revoked.pub" ]
    run ! grep -q "Host revoke.example.com" "$HOME/.ssh/config"
}

# ---------------------------------------------------------------------------
# rotate
# ---------------------------------------------------------------------------

@test "rotate without --host exits non-zero" {
    run "$SCRIPT" rotate --comment "Test"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "rotate without --comment exits non-zero" {
    run "$SCRIPT" rotate --host rotate.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--comment not specified" ]]
}

@test "rotate for unknown host exits non-zero" {
    run "$SCRIPT" rotate --host unknown.example.com --comment "Rotate test"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Could not find host key" ]]
}

@test "rotate creates new key and backs up old key" {
    "$SCRIPT" create --host rotatehost.example.com --comment "Original key"
    OLD_KEY_CONTENT=$(cat "$HOME/.ssh/id_rotatehost.example.com.pub")
    run "$SCRIPT" rotate --host rotatehost.example.com --comment "Rotated key" --no-password
    [ "$status" -eq 0 ]
    [ -f "$HOME/.ssh/id_rotatehost.example.com" ]
    [ -f "$HOME/.ssh/id_rotatehost.example.com.pub" ]
    [ -f "$HOME/.ssh/old/id_rotatehost.example.com.old" ]
    [ -f "$HOME/.ssh/old/id_rotatehost.example.com.old.pub" ]
    # New key must differ from old key
    NEW_KEY_CONTENT=$(cat "$HOME/.ssh/id_rotatehost.example.com.pub")
    [ "$NEW_KEY_CONTENT" != "$OLD_KEY_CONTENT" ]
}

@test "rotate skips key server when KEYS_SERVER_URL is unset" {
    "$SCRIPT" create --host rotateskip.example.com --comment "Original"
    run "$SCRIPT" rotate --host rotateskip.example.com --comment "Rotated" --no-password
    [ "$status" -eq 0 ]
    [[ "$output" =~ "KEYS_SERVER_URL not set" ]]
}

# ---------------------------------------------------------------------------
# alias
# ---------------------------------------------------------------------------

@test "alias without --host exits non-zero" {
    run "$SCRIPT" alias --additional-host alias.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "alias without --additional-host exits non-zero" {
    run "$SCRIPT" alias --host main.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--additional-host not specified" ]]
}

@test "alias for unknown host exits non-zero" {
    run "$SCRIPT" alias --host unknown.example.com --additional-host alias.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Could not find host key" ]]
}

@test "alias adds new hostname to existing host entry" {
    "$SCRIPT" create --host aliasbase.example.com --comment "Alias base"
    run "$SCRIPT" alias --host aliasbase.example.com --additional-host aliasname.example.com
    [ "$status" -eq 0 ]
    grep -q "aliasname.example.com" "$HOME/.ssh/config"
}

@test "alias for already-aliased host exits non-zero" {
    "$SCRIPT" create --host dupaliasbase.example.com --comment "Dup alias base"
    "$SCRIPT" alias --host dupaliasbase.example.com --additional-host dupaliasname.example.com
    run "$SCRIPT" alias --host dupaliasbase.example.com --additional-host dupaliasname.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Alias already in host" ]]
}

# ---------------------------------------------------------------------------
# import
# ---------------------------------------------------------------------------

@test "import without --host exits non-zero" {
    run "$SCRIPT" import --source /tmp/somekey
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "import without --source exits non-zero" {
    run "$SCRIPT" import --host importhost.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--source not specified" ]]
}

@test "import with missing source file exits non-zero" {
    run "$SCRIPT" import --host importhost.example.com --source /nonexistent/key
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Source private key does not exist" ]]
}

@test "import copies private and public key to ssh dir and adds config entry" {
    # Generate a temporary key pair to use as import source
    SOURCE_DIR="$BATS_TEST_TMPDIR/source"
    mkdir -p "$SOURCE_DIR"
    ssh-keygen -t ed25519 -C "import test" -P "" -f "$SOURCE_DIR/testkey" -q
    run "$SCRIPT" import --host imported.example.com --source "$SOURCE_DIR/testkey"
    [ "$status" -eq 0 ]
    [ -f "$HOME/.ssh/id_imported.example.com" ]
    [ -f "$HOME/.ssh/id_imported.example.com.pub" ]
    grep -q "Host imported.example.com" "$HOME/.ssh/config"
    # Verify the public key destination contains public key content
    grep -q "ssh-ed25519" "$HOME/.ssh/id_imported.example.com.pub"
}

@test "import for host already in config exits non-zero" {
    "$SCRIPT" create --host existingimport.example.com --comment "Existing"
    SOURCE_DIR="$BATS_TEST_TMPDIR/source2"
    mkdir -p "$SOURCE_DIR"
    ssh-keygen -t ed25519 -C "dup import" -P "" -f "$SOURCE_DIR/testkey" -q
    run "$SCRIPT" import --host existingimport.example.com --source "$SOURCE_DIR/testkey"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Host already in the SSH config" ]]
}

# ---------------------------------------------------------------------------
# use
# ---------------------------------------------------------------------------

@test "use without --host exits non-zero" {
    run "$SCRIPT" use
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "use without SSH_AUTH_SOCK exits non-zero" {
    "$SCRIPT" create --host usehost.example.com --comment "Use test"
    unset SSH_AUTH_SOCK
    run "$SCRIPT" use --host usehost.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "SSH_AUTH_SOCK not defined" ]]
}

@test "use for unknown host exits non-zero" {
    export SSH_AUTH_SOCK=/tmp/fake-agent.sock
    run "$SCRIPT" use --host unknown.example.com
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Could not find host key" ]]
}

# ---------------------------------------------------------------------------
# upload
# ---------------------------------------------------------------------------

@test "upload without --host exits non-zero" {
    run "$SCRIPT" upload
    [ "$status" -ne 0 ]
    [[ "$output" =~ "--host not specified" ]]
}

@test "upload for unknown host exits non-zero" {
    export KEYS_SERVER_URL="http://localhost:9999"
    run "$SCRIPT" upload --host unknown.example.com --user testuser
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Could not find host key" ]]
}

@test "upload without KEYS_SERVER_URL exits non-zero" {
    "$SCRIPT" create --host uploadhost.example.com --comment "Upload test"
    unset KEYS_SERVER_URL
    run "$SCRIPT" upload --host uploadhost.example.com --user testuser
    [ "$status" -ne 0 ]
    [[ "$output" =~ "KEYS_SERVER_URL is not set" ]]
}

# ---------------------------------------------------------------------------
# audit
# ---------------------------------------------------------------------------

@test "audit with no keys exits zero" {
    run "$SCRIPT" audit
    [ "$status" -eq 0 ]
}

@test "audit lists key details for installed keys" {
    "$SCRIPT" create --host audithost.example.com --comment "Audit test"
    run "$SCRIPT" audit
    [ "$status" -eq 0 ]
    [[ "$output" =~ id_audithost.example.com ]]
}

@test "audit warns when default id_ed25519 key exists" {
    mkdir -p "$HOME/.ssh"
    touch "$HOME/.ssh/id_ed25519"
    touch "$HOME/.ssh/id_ed25519.pub"
    run "$SCRIPT" audit
    [[ "$output" =~ "Warning: default id_ed25519 key files exist" ]]
}
