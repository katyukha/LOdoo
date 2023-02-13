#!/usr/bin/env bash

# Fail on any error
set -e;

function _python {
    python3 "$@";
}

# Run lodoo with coverage
function _lodoo {
    _python -m coverage run -a --source=lodoo -m lodoo "$@";
}


# Check that database does not exists
! _lodoo db-exists my-database;

# Create test database
_lodoo db-create --demo my-database;
_lodoo db-exists my-database;

# Check that list database is not empty
[ -n "$(_lodoo db-list)" ];

# Copy test database
_lodoo db-copy my-database my-database-copy;
_lodoo db-exists my-database-copy;

# Backup test database
_lodoo db-backup --format=zip my-database my-backup1.zip;
[ -f my-backup1.zip ];

# Drop my database
_lodoo db-drop my-database;
! _lodoo db-exists my-database;

# Try to restore database
_lodoo db-restore my-database my-backup1.zip;
_lodoo db-exists my-database;

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
_lodoo db-exists my-database-copy;
_lodoo db-exists my-database-new;

[ -z "$(_lodoo db-list)" ];
