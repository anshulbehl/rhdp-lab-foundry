#!/bin/bash
# No set -euo pipefail here: the curl wait loop must survive failures

echo "Starting Control node setup (configure phase)..."
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

AAP_HOST="https://localhost"
AAP_USER="admin"
AAP_PASS="ansible123!"

###############################################################################
# 1. Wait for AAP to be ready
###############################################################################

echo "Waiting for AAP controller to be ready..."
for i in $(seq 1 60); do
    CODE=$(curl -sk -o /dev/null -w "%{http_code}" \
        "${AAP_HOST}/api/controller/v2/ping/" \
        -u "${AAP_USER}:${AAP_PASS}" 2>/dev/null)
    if [ "$CODE" = "200" ]; then
        echo "  AAP ready (attempt $i)"
        break
    fi
    if [ "$i" = "60" ]; then
        echo "FATAL: AAP not ready after 60 attempts"
        exit 1
    fi
    echo "  waiting... (attempt $i, HTTP $CODE)"
    sleep 10
done

###############################################################################
# 2. Generate OAuth token for ansible.controller modules
###############################################################################

echo "Generating AAP OAuth token..."
CONTROLLER_OAUTH_TOKEN=$(curl -sk -X POST \
    "${AAP_HOST}/api/controller/v2/tokens/" \
    -H "Content-Type: application/json" \
    -u "${AAP_USER}:${AAP_PASS}" \
    -d '{"description":"setup-automation","application":null,"scope":"write"}' | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [ -z "${CONTROLLER_OAUTH_TOKEN}" ]; then
    echo "ERROR: Failed to generate AAP OAuth token"
    exit 1
fi
echo "  Token generated OK"
export CONTROLLER_OAUTH_TOKEN

TOKEN_VAR="controller_oauth_token=${CONTROLLER_OAUTH_TOKEN}"

###############################################################################
# 3. Create inline configure playbook
###############################################################################

export CONTROLLER_HOST="${AAP_HOST}"
export CONTROLLER_OAUTH_TOKEN
export CONTROLLER_VERIFY_SSL=false

cat > /tmp/configure-aap.yml << 'PLAYBOOK'
---
- name: Configure AAP for Linux Patching Lab
  hosts: localhost
  connection: local
  gather_facts: false

  module_defaults:
    group/ansible.controller.controller:
      controller_host: "{{ lookup('env', 'CONTROLLER_HOST') }}"
      controller_oauthtoken: "{{ lookup('env', 'CONTROLLER_OAUTH_TOKEN') }}"
      validate_certs: false

  tasks:
    - name: Create machine credential
      ansible.controller.credential:
        name: "Lab Machine Credential"
        organization: "Default"
        credential_type: "Machine"
        inputs:
          username: rhel
          password: ansible123!
          become_method: sudo
          become_password: ansible123!
        state: present

    - name: Create project from lab GitHub repo
      ansible.controller.project:
        name: "Linux Patching"
        organization: "Default"
        scm_type: git
        scm_url: "https://github.com/anshulbehl/zt-ans-linux-patching.git"
        scm_branch: main
        scm_update_on_launch: false
        state: present
        wait: true
        timeout: 120

    - name: Create inventory
      ansible.controller.inventory:
        name: "Lab Inventory"
        organization: "Default"
        state: present

    - name: Add node1 to inventory
      ansible.controller.host:
        name: node1
        inventory: "Lab Inventory"
        state: present

    - name: Create Pre-Patch Check template
      ansible.controller.job_template:
        name: "LINUX | Pre-Patch Check"
        organization: "Default"
        project: "Linux Patching"
        playbook: playbooks/pre_patch_check.yml
        inventory: "Lab Inventory"
        credential: "Lab Machine Credential"
        job_type: run
        state: present

    - name: Create Apply Patches template
      ansible.controller.job_template:
        name: "LINUX | Apply Patches"
        organization: "Default"
        project: "Linux Patching"
        playbook: playbooks/apply_patches.yml
        inventory: "Lab Inventory"
        credential: "Lab Machine Credential"
        job_type: run
        state: present

    - name: Create Post-Patch Validation template
      ansible.controller.job_template:
        name: "LINUX | Post-Patch Validation"
        organization: "Default"
        project: "Linux Patching"
        playbook: playbooks/post_patch_validation.yml
        inventory: "Lab Inventory"
        credential: "Lab Machine Credential"
        job_type: run
        state: present

    - name: Create Patch Report template
      ansible.controller.job_template:
        name: "LINUX | Patch Report"
        organization: "Default"
        project: "Linux Patching"
        playbook: playbooks/patch_report.yml
        inventory: "Lab Inventory"
        credential: "Lab Machine Credential"
        job_type: run
        state: present
PLAYBOOK

###############################################################################
# 4. Run the configure playbook
###############################################################################

ansible-playbook /tmp/configure-aap.yml -e "${TOKEN_VAR}"

echo ""
echo "Control configure phase complete."
echo "  Credential: Lab Machine Credential"
echo "  Inventory: Lab Inventory (node1)"
echo "  Project: Linux Patching"
echo "  Templates: Pre-Patch Check, Apply Patches, Post-Patch Validation, Patch Report"
