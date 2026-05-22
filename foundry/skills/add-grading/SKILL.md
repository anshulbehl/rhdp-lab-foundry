---
name: foundry:add-grading
description: Generate solve and validate scripts for lab modules. Creates shell scripts or Ansible playbooks that automate what students do (solve) and verify they did it correctly (validate). Delegates to ftl:rhdp-lab-validator when available. Use when asked to "add grading", "add solve/validate", "add testing", "generate validation scripts", or "add E2E testing".
context: main
model: claude-sonnet-4-6
---

# Add Grading - Generate Solve and Validate Scripts

Creates solve (solution) and validate (verification) scripts for lab modules.

## Three Approaches

### Shell Script Grading (Traditional)
Simple bash scripts in runtime-automation/module-NN/:
- `solve-control.sh`: Automates what the student should do
- `validation-control.sh`: Checks if the student did it correctly (exit 0 = pass, exit 1 = fail)

### Ansible Grading (FTL)
Ansible playbooks using the Full Test Lifecycle framework:
- `solve.yml`: Ansible playbook that automates the solution
- `validate.yml`: Ansible playbook that verifies the result

### API-Driven Grading (Recommended for labs with AAP/Vault/TFE)
Ansible playbooks that use `ansible.builtin.uri` to call service REST APIs directly.
No SSH access or Ansible collections needed. Runs from the Showroom runner container.

This approach was proven at Summit 2026 in the HashiCorp lab (LB1390, most popular lab).
See `foundry/references/zt-hashi-aap.md` for the full pattern.

- `solve.yml`: Creates resources via API POST calls (idempotent, 400 = already exists)
- `validation.yml`: Queries resources via API GET calls, asserts they exist

Best for labs where students:
- Create AAP credentials, job templates, workflows, inventories
- Configure Vault secret engines, policies, auth methods
- Set up TFE workspaces, variables, VCS connections
- Create OPA policies or NetBox objects

## Workflow

1. Read the content module (.adoc) to understand what students do
2. Ask: Shell scripts, Ansible playbooks, or API-driven?
3. If API-driven: identify which services have REST APIs (AAP, Vault, TFE, OPA, NetBox)
4. Generate the scripts/playbooks with appropriate checks
5. If ftl:rhdp-lab-validator is available, offer to delegate:
   "Want me to use the FTL lab validator for more robust solve/validate generation?"

## Shell Script Template

```bash
#!/bin/bash
# solve-control.sh for module-{NN}: {title}
# Automates what the student does in this module

set -euo pipefail

echo "Solving module {NN}: {title}"

# TODO: Add solution steps
# Example: Run the ansible playbook the student would run
# ansible-playbook /path/to/playbook.yml

echo "Module {NN} solved successfully"
```

```bash
#!/bin/bash
# validation-control.sh for module-{NN}: {title}
# Verifies the student completed the module correctly

set -euo pipefail

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $desc"
        ((PASS++))
    else
        echo "FAIL: $desc"
        ((FAIL++))
    fi
}

# TODO: Add validation checks
# Example:
# check "Playbook created" test -f /home/student/playbook.yml
# check "Service running" systemctl is-active httpd

echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
```

## API-Driven Template

```yaml
---
# validation.yml for module-{NN}: {title}
# Verifies student completed the module by querying service APIs.
# Runs from the Showroom runner container (no SSH, no collections).

- name: Validate module {NN}
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    aap_host: "https://{{ aap_hostname }}"
    aap_user: "admin"
    aap_pass: "ansible123!"

  tasks:
    # Pattern: query by name, assert count > 0
    - name: "Check: {resource_type} '{resource_name}' exists"
      ansible.builtin.uri:
        url: "{{ aap_host }}/api/controller/v2/{endpoint}/?name={{ '{resource_name}' | urlencode }}"
        url_username: "{{ aap_user }}"
        url_password: "{{ aap_pass }}"
        method: GET
        validate_certs: false
        force_basic_auth: true
        status_code: 200
      register: check_result

    - name: "Verify: {resource_name}"
      ansible.builtin.assert:
        that: check_result.json.count > 0
        fail_msg: "{resource_type} '{resource_name}' not found in AAP"
        success_msg: "{resource_type} '{resource_name}' exists"
```

```yaml
---
# solve.yml for module-{NN}: {title}
# Creates all resources the student should have created.
# Idempotent: 400 status = resource already exists.

- name: Solve module {NN}
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    aap_host: "https://{{ aap_hostname }}"
    aap_user: "admin"
    aap_pass: "ansible123!"

  tasks:
    # Pattern: POST to create, accept 200/201/400
    - name: "Create: {resource_name}"
      ansible.builtin.uri:
        url: "{{ aap_host }}/api/controller/v2/{endpoint}/"
        url_username: "{{ aap_user }}"
        url_password: "{{ aap_pass }}"
        method: POST
        validate_certs: false
        force_basic_auth: true
        body_format: json
        body:
          name: "{resource_name}"
          organization: 1
          # Add resource-specific fields
        status_code: [200, 201]
      register: result
      failed_when: result.status not in [200, 201, 400]
```

### API Endpoints Reference

When generating API-driven grading, use these endpoints:

| What to check | AAP API endpoint | Method |
|:--------------|:-----------------|:-------|
| Credential types | /api/controller/v2/credential_types/ | GET (list), POST (create) |
| Credentials | /api/controller/v2/credentials/ | GET, POST |
| Projects | /api/controller/v2/projects/ | GET, POST |
| Inventories | /api/controller/v2/inventories/ | GET, POST |
| Inventory sources | /api/controller/v2/inventory_sources/ | GET, POST |
| Job templates | /api/controller/v2/job_templates/ | GET, POST |
| Workflow templates | /api/controller/v2/workflow_job_templates/ | GET, POST |
| Workflow nodes | /api/controller/v2/workflow_job_template_nodes/ | GET, POST |
| Node success links | ...nodes/{id}/success_nodes/ | POST |
| Execution environments | /api/controller/v2/execution_environments/ | GET, POST |
| Teams | /api/controller/v2/teams/ | GET, POST |
| Roles | /api/controller/v2/role_assignments/ | GET, POST |

| What to check | Vault API endpoint | Method |
|:--------------|:-------------------|:-------|
| Health | /v1/sys/health | GET |
| Secret engines | /v1/sys/mounts | GET |
| KV secret | /v1/secret/data/{path} | GET, POST |
| Auth methods | /v1/sys/auth | GET |
| Policies | /v1/sys/policies/acl/{name} | GET, PUT |
| AppRole role | /v1/auth/approle/role/{name} | GET, POST |
| AppRole role_id | /v1/auth/approle/role/{name}/role-id | GET |

| What to check | TFE API endpoint | Method |
|:--------------|:-----------------|:-------|
| Workspaces | /api/v2/organizations/{org}/workspaces | GET, POST |
| Workspace vars | /api/v2/workspaces/{id}/vars | GET, POST |
| Projects | /api/v2/organizations/{org}/projects | GET |
