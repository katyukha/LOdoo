#!/usr/bin/env bash

SCRIPT=$0;
SCRIPT_NAME=$(basename "$SCRIPT");
SCRIPT_DIR=$(dirname "$SCRIPT");
LODOO_DIR=$(realpath "$SCRIPT_DIR/../../");
WORKDIR=$(pwd);
TEST_V7_ROOT=${TEST_V7_ROOT:-$WORKDIR};

export DEBIAN_FRONTEND='noninteractive'

apt-get update
apt-get install -yq --no-install-recommends \
    build-essential \
    python2-dev \
    python2-pip-whl \
    python2-setuptools-whl \
    python3-dev \
    python3-virtualenv \
    sudo \
    wget \
    postgresql \
    libssl-dev \
    python3 \
    python3-virtualenv \
    libpq-dev \
    libsass-dev \
    libjpeg-dev \
    libyaml-dev \
    libfreetype6-dev \
    zlib1g-dev \
    libxml2-dev \
    libxslt-dev \
    bzip2 \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    libffi-dev \
    fontconfig \
    libmagic1;

wget -O "/tmp/odoo.tar.gz" https://github.com/odoo/odoo/archive/7.0.tar.gz
tar -xzf "/tmp/odoo.tar.gz"

mkdir "$TEST_V7_ROOT/odoo/";

python3 -m virtualenv -p python2 "$TEST_V7_ROOT/odoo/venv"
mv odoo-7.0 "$TEST_V7_ROOT/odoo/venv/odoo"
sed -i -r "s/PIL/Pillow/" "$TEST_V7_ROOT/odoo/venv/odoo/setup.py";
sed -i -r "s/pychart/Python-Chart/" "$TEST_V7_ROOT/odoo/venv/odoo/setup.py";
(source "$TEST_V7_ROOT/odoo/venv/bin/activate" && \
    pip install -r "$LODOO_DIR/.ci/v7/requirements.txt" && \
    (cd "$TEST_V7_ROOT/odoo/venv/odoo" && python setup.py develop) && \
    (cd "$LODOO_DIR" && python setup.py develop) && \
    echo "---"
)


useradd --home "$TEST_V7_ROOT/odoo/" odoo;
chown odoo:odoo -R "$TEST_V7_ROOT/odoo";

echo "Updating configuration of Odoo...";
sudo -u odoo -H -- "$TEST_V7_ROOT/odoo/venv/bin/openerp-server" \
    --db_user="${POSTGRES_USER:-odoo}" \
    --db_password="${POSTGRES_PASSWORD:-odoo}" \
    --db_host="$TEST_DB_HOST" \
    --addons-path="$TEST_V7_ROOT/odoo/venv/odoo/addons/,$TEST_V7_ROOT/odoo/venv/odoo/openerp/addons" \
    -s --stop-after-init
echo "Odoo config updates completed!";
