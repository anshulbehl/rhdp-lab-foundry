#!/bin/bash
set -euo pipefail

echo "Starting Control node setup (bootstrap phase)..."
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

###############################################################################
# Helpers
###############################################################################

retry() {
    local max_attempts=3
    local delay=5
    local desc="$1"
    shift
    for ((i = 1; i <= max_attempts; i++)); do
        echo "Attempt $i/$max_attempts: $desc"
        if "$@"; then
            return 0
        fi
        if [ $i -lt $max_attempts ]; then
            echo "  Failed. Retrying in ${delay}s..."
            sleep $delay
        fi
    done
    echo "FATAL: Failed after $max_attempts attempts: $desc"
    exit 1
}

run_if_needed() {
    local desc="$1"
    shift
    local check=()
    while [[ $# -gt 0 && "${1}" != "--" ]]; do
        check+=("$1"); shift
    done
    shift
    if "${check[@]}" &>/dev/null; then
        echo "SKIP (already done): $desc"
    else
        retry "$desc" "$@"
    fi
}

###############################################################################
# 1. Validate required environment variables
###############################################################################

for var in AH_TOKEN; do
    if [ -z "${!var:-}" ]; then
        echo "ERROR: $var environment variable is not set"
        exit 1
    fi
done

###############################################################################
# 2. Setup Ansible configuration with AH Token
###############################################################################

tee ~/.ansible.cfg > /dev/null <<EOF
[defaults]
host_key_checking = False
[galaxy]
server_list = automation_hub, validated, galaxy
[galaxy_server.automation_hub]
url = https://console.redhat.com/api/automation-hub/content/published/
auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
token=$AH_TOKEN
[galaxy_server.validated]
url = https://console.redhat.com/api/automation-hub/content/validated/
auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
token=$AH_TOKEN
[galaxy_server.galaxy]
url=https://galaxy.ansible.com/
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF

###############################################################################
# 3. Install packages
###############################################################################

run_if_needed "Install base packages" \
    rpm -q git \
    -- \
    dnf install -y dnf-utils git

###############################################################################
# 4. Install Ansible collections
###############################################################################

tee /tmp/requirements.yml > /dev/null <<EOF
---
collections:
  - name: ansible.controller
  - name: ansible.posix
  - name: community.general
EOF

run_if_needed "Install Ansible collections" \
    bash -c 'ansible-galaxy collection list | grep -q "ansible.controller"' \
    -- \
    ansible-galaxy collection install -r /tmp/requirements.yml

if ! ansible-galaxy collection list 2>/dev/null | grep -q "ansible.controller"; then
    echo "INFO: ansible.controller not found; symlinking awx.awx"
    mkdir -p ~/.ansible/collections/ansible_collections/ansible
    ln -sfn ~/.ansible/collections/ansible_collections/awx/awx \
            ~/.ansible/collections/ansible_collections/ansible/controller
fi

echo ""
echo "Control bootstrap phase complete."
