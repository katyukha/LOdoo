#!/usr/bin/env bash

SCRIPT=$0;
SCRIPT_NAME=$(basename "$SCRIPT");
SCRIPT_DIR=$(dirname "$SCRIPT");
LODOO_PATH=$(realpath "$SCRIPT_DIR/../src/lodoo.py");
WORKDIR=$(pwd);

# Assert that command runs successfully
function _assert_cmd_ok {
    if "$@"; then
        return 0;
    else
        local res=$?;
        >&2 echo -e "ERROR: Command '$@' returned '$res' exit-code!";
        return $res;
    fi
}

# Assert that command fails
function _assert_cmd_fail {
    if "$@"; then
        >&2 echo -e "ERROR: Command '$@' expected to fail, but completed successfully!";
        exit 1;
    else
        return 0;
    fi
}

# Assert that variable is not null
function _assert_var_not_null {
    #if [ -z "$
    local var_name="$1";
    if [ -z "${!var_name:-}" ]; then
        >&2 echo -e "ERROR: Variable '$var_name' is not set!";
        exit 1;
    fi
}

# Fail on any error
set -e;

if [ -n "$TEST_V7_ROOT" ]; then
    source "$TEST_V7_ROOT/odoo/venv/bin/activate";
fi

_assert_var_not_null "TEST_PY_VERSION";

[ "$TEST_PY_VERSION" -eq 2 ] || [ "$TEST_PY_VERSION" -eq 3 ];

function _python {
    "python${TEST_PY_VERSION}" "$@";
}

# Run lodoo with coverage
function _lodoo {
    _python -m coverage run -a --source="lodoo" "$LODOO_PATH" "$@";
}


>&2 echo -e "INFO: Start testing!";

# Check that database does not exists
_assert_cmd_fail _lodoo db-exists my-database;

# Create test database
>&2 echo -e "INFO: Create test database!";
_assert_cmd_ok _lodoo db-create --demo my-database;
_assert_cmd_ok _lodoo db-exists my-database;

# Check that we have here 1 database
>&2 echo -e "INFO: Check that db-list returns 1 line!";
if ! [ "$(_lodoo db-list | wc -l)" -eq 1 ]; then
    >&2 echo -e "ERROR: expected only one database created!";
    >&2 echo -e "ERROR: db-list output:\n'$(_lodoo db-list)'";
    exit 1;
fi

# Copy test database
>&2 echo -e "INFO: Try to copy database!";
_assert_cmd_ok _lodoo db-copy my-database my-database-copy;
_assert_cmd_ok _lodoo db-exists my-database-copy;

# Check that we have here 2 databases
#[ "$(_lodoo db-list | wc -l)" -eq 2 ];
>&2 echo -e "INFO: Check that there are 2 databases now!";
if ! [ "$(_lodoo db-list | wc -l)" -eq 2 ]; then
    >&2 echo -e "ERROR: expected 2 databases!";
    >&2 echo -e "ERROR: db-list output:\n'$(_lodoo db-list)'";
    exit 1;
fi

# Backup test database
>&2 echo -e "INFO: Take backup of database!";
if [ -n "$TEST_V7_ROOT" ]; then
    _assert_cmd_ok _lodoo db-backup --format=sql my-database my-backup1.sql;
    [ -f my-backup1.sql ];
else
    _assert_cmd_ok _lodoo db-backup --format=zip my-database my-backup1.zip;
    [ -f my-backup1.zip ];
fi

# Drop my database
>&2 echo -e "INFO: Drop existing database!";
_assert_cmd_ok _lodoo db-drop my-database;
_assert_cmd_fail _lodoo db-exists my-database;

# Check that we have here 1 database
#[ "$(_lodoo db-list | wc -l)" -eq 1 ];
>&2 echo -e "INFO: Check that db-list returns 1 line!";
if ! [ "$(_lodoo db-list | wc -l)" -eq 1 ]; then
    >&2 echo -e "ERROR: expected only one database created!";
    >&2 echo -e "ERROR: db-list output:\n'$(_lodoo db-list)'";
    exit 1;
fi

# Try to restore database
>&2 echo -e "INFO: Try to restore database from backup!";
if [ -n "$TEST_V7_ROOT" ]; then
    _assert_cmd_ok _lodoo db-restore my-database my-backup1.sql;
else
    _assert_cmd_ok _lodoo db-restore my-database my-backup1.zip;
fi
_assert_cmd_ok _lodoo db-exists my-database;

# Check that we have here 2 databases
#[ "$(_lodoo db-list | wc -l)" -eq 2 ];
>&2 echo -e "INFO: Check that there are 2 databases now!";
if ! [ "$(_lodoo db-list | wc -l)" -eq 2 ]; then
    >&2 echo -e "ERROR: expected 2 databases!";
    >&2 echo -e "ERROR: db-list output:\n'$(_lodoo db-list)'";
    exit 1;
fi

# Try to print dump-manifest for this database
>&2 echo -e "INFO: Try to print dump manifest for my-database!";
_assert_cmd_ok _lodoo db-dump-manifest my-database;

# Try to run addons-update-list cmd on my database
>&2 echo -e "INFO: Try to Update list of addons!";
_assert_cmd_ok _lodoo addons-update-list my-database;

# Try to rename database
>&2 echo -e "INFO: Try to rename database!";
_assert_cmd_ok _lodoo db-rename my-database my-database-new;
_assert_cmd_fail _lodoo db-exists my-database;
_assert_cmd_ok _lodoo db-exists my-database-copy;
_assert_cmd_ok _lodoo db-exists my-database-new;

# Drop test databases
>&2 echo -e "INFO: Drop databases!";
_assert_cmd_ok _lodoo db-drop my-database-new;
_assert_cmd_ok _lodoo db-drop my-database-copy;

# Ensure test databases dropt
>&2 echo -e "INFO: Test that databases not exists!";
_assert_cmd_fail _lodoo db-exists my-database-copy;
_assert_cmd_fail _lodoo db-exists my-database-new;

# Ensure there are no databases exist
#[ "$(_lodoo db-list | wc -l)" -eq 0 ];
>&2 echo -e "INFO: db list prodices zero lines output!";
if ! [ "$(_lodoo db-list | wc -l)" -eq 0 ]; then
    >&2 echo -e "ERROR: expected 0 databases!";
    >&2 echo -e "ERROR: db-list output:\n'$(_lodoo db-list)'";
    exit 1;
fi

echo -e "Test completed";
