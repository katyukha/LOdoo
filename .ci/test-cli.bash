#!/usr/bin/env bash

# Fail on any error
set -e;

[ -n "${COV_DATA_FILE}" ];
[ -n "${COV_CONTEXT}" ];
[ -n "${TEST_PY_VERSION}" ];
[ "$TEST_PY_VERSION" -eq 2 ] || [ "$TEST_PY_VERSION" -eq 3 ];

function _python {
    "python${TEST_PY_VERSION}" "$@";
}

# Run lodoo with coverage
function _lodoo {
    _python -m coverage run -a --data-file=${COV_DATA_FILE} --context="${COV_CONTEXT}" --source="lodoo" "$(pwd)/src/lodoo.py" "$@";
}


# Check that database does not exists
! _lodoo db-exists my-database;

# Create test database
_lodoo db-create --demo my-database;
_lodoo db-exists my-database;

# Check that we have here 1 database
[ "$(_lodoo db-list | wc -l)" -eq 1 ];

# Copy test database
_lodoo db-copy my-database my-database-copy;
_lodoo db-exists my-database-copy;

# Check that we have here 2 databases
[ "$(_lodoo db-list | wc -l)" -eq 2 ];

# Backup test database
_lodoo db-backup --format=zip my-database my-backup1.zip;
[ -f my-backup1.zip ];

# Drop my database
_lodoo db-drop my-database;
! _lodoo db-exists my-database;

# Check that we have here 1 database
[ "$(_lodoo db-list | wc -l)" -eq 1 ];

# Try to restore database
_lodoo db-restore my-database my-backup1.zip;
_lodoo db-exists my-database;

# Check that we have here 2 databases
[ "$(_lodoo db-list | wc -l)" -eq 2 ];

# Try to print dump-manifest for this database
_lodoo db-dump-manifest my-database;

# Try to run addons-update-list cmd on my database
_lodoo addons-update-list my-database;

# Try to rename database
_lodoo db-rename my-database my-database-new;
! _lodoo db-exists my-database;
_lodoo db-exists my-database-copy;
_lodoo db-exists my-database-new;

# Drop test databases
_lodoo db-drop my-database-new;
_lodoo db-drop my-database-copy;

# Ensure test databases dropt
! _lodoo db-exists my-database-copy;
! _lodoo db-exists my-database-new;

# Ensure there are no databases exist
[ "$(_lodoo db-list | wc -l)" -eq 0 ];

echo -e "Test completed";
