---
name: foundry:validate-lab
description: Validate a lab's structure, infrastructure config, content quality, and deployment health. Generates validation scripts with webhook reporting so you get notified when provisioning fails. Supports skip configuration. Use when asked to "validate my lab", "check my lab", "add validation", "add health checks", or "set up provisioning notifications".
context: main
model: claude-sonnet-4-6
---

# Validate Lab - Comprehensive Lab Validation with Health Reporting

Validates a lab across multiple dimensions and generates provisioning health check scripts that report results via webhook.

## Validation Stages

Each stage can be skipped via `.foundry-skip` or `--skip` argument.

### Stage 1: structure
Verify the lab has all required files for its type.

**Zero-touch requirements:**
- [ ] config/instances.yaml exists and is valid YAML
- [ ] config/firewall.yaml exists
- [ ] config/networks.yaml exists
- [ ] setup-automation/main.yml exists
- [ ] At least one setup-*.sh script exists
- [ ] runtime-automation/main.yml exists
- [ ] content/antora.yml exists
- [ ] content/modules/ROOT/nav.adoc exists
- [ ] At least one page in content/modules/ROOT/pages/
- [ ] ui-config.yml exists
- [ ] site.yml exists

**AgnosticV requirements:**
- [ ] common.yaml exists and has env_type, cloud_provider
- [ ] common.yaml: git_config_directory URL is reachable (fetch test)
- [ ] common.yaml: referenced content repo's config/instances.yaml parses correctly
- [ ] common.yaml: #include directives reference existing files
- [ ] common.yaml: __meta__.components reference valid catalog items
- [ ] dev.yaml exists
- [ ] description.adoc exists
- [ ] If using base-component: verify base-component version hasn't introduced breaking changes

This is critical because the RHDP team sometimes pushes changes to shared components
(like base-component or includes/) without lab developer review, breaking downstream labs.
The validate stage catches this by verifying all references still resolve.

**Showroom-only requirements:**
- [ ] content/antora.yml exists
- [ ] ui-config.yml exists
- [ ] site.yml exists

### Stage 2: config
Validate infrastructure configuration.

- [ ] instances.yaml: all VMs have name, image, memory, cores
- [ ] instances.yaml: all containers have name, image
- [ ] instances.yaml: routes have valid TLS termination (Edge/Reencrypt)
- [ ] instances.yaml: services have ports defined
- [ ] firewall.yaml: has ingress rules for all service ports
- [ ] firewall.yaml: egress is not wide-open (no 0.0.0.0/0 allow-all)
- [ ] networks.yaml: valid structure
- [ ] ui-config.yml: tabs reference valid routes from instances.yaml

### Stage 3: content
Delegate to showroom:verify-content if available.

If not available, basic checks:
- [ ] All .adoc files in pages/ are valid AsciiDoc
- [ ] nav.adoc references all page files
- [ ] No broken internal xrefs
- [ ] Module numbering is sequential (01, 02, 03...)

### Stage 4: automation
Validate setup and runtime automation.

- [ ] setup-automation/main.yml is valid Ansible
- [ ] setup scripts reference correct hostnames from instances.yaml
- [ ] Setup scripts include wait-for-ready patterns (grep for retry/until/wait)
- [ ] runtime-automation module directories match content modules
- [ ] Each module has at least setup script

### Stage 5: catalog
Delegate to agnosticv:validator if available.

Only runs if .foundry.yml indicates lab_type is agnosticv or if common.yaml exists.

### Stage 6: ftl
Check for solve/validate scripts in runtime-automation.

- [ ] Each module directory has solve-*.sh or solve.yml
- [ ] Each module directory has validation-*.sh or validate.yml
- [ ] Scripts are executable

### Stage 6b: api-validation (new)
Generate API-driven validation scripts for labs with AAP, Vault, TFE, or other API-accessible services.

This pattern comes from the HashiCorp Summit lab (zt-ans-bu-hashi-aap, lb1390-validation branch)
where solve/validate uses pure `ansible.builtin.uri` calls instead of SSH scripts. This approach
works from the Showroom runner container which has no SSH access to lab VMs and no Ansible
collections installed.

See `foundry/references/zt-hashi-aap.md` for the full pattern.

**When to generate API validation:**
- Lab has AAP controller (most zero-touch labs)
- Lab has Vault, TFE, OPA, NetBox, or other services with REST APIs
- Lab uses workflow job templates or custom credential types

**What gets generated:**

For each module, generate `runtime-automation/module-NN/validation.yml`:
```yaml
---
- name: Validate module NN
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    aap_host: "https://control.{{ lab_domain }}"
    aap_user: "admin"
    aap_pass: "ansible123!"

  tasks:
    # AAP resource checks: verify resources exist via API query
    - name: "Check: credential type exists"
      ansible.builtin.uri:
        url: "{{ aap_host }}/api/controller/v2/credential_types/"
        url_username: "{{ aap_user }}"
        url_password: "{{ aap_pass }}"
        method: GET
        validate_certs: false
        force_basic_auth: true
        body_format: json
        status_code: 200
      register: result

    - name: "Verify: credential type present"
      ansible.builtin.assert:
        that: result.json.count > 0
        fail_msg: "Expected credential type not found"

    # Vault checks (if applicable)
    - name: "Check: Vault secret engine mounted"
      ansible.builtin.uri:
        url: "http://vault.{{ lab_domain }}:8200/v1/sys/mounts"
        headers:
          X-Vault-Token: "{{ vault_token }}"
        status_code: [200, 403]
      register: vault_mounts
```

**Solve script pattern:**

For each module, optionally generate `runtime-automation/module-NN/solve.yml` that
creates all the resources the student should have created, using the same API approach:
```yaml
    # Create resource via API (no collections needed)
    - name: "Create credential in AAP"
      ansible.builtin.uri:
        url: "{{ aap_host }}/api/controller/v2/credentials/"
        url_username: "{{ aap_user }}"
        url_password: "{{ aap_pass }}"
        method: POST
        validate_certs: false
        force_basic_auth: true
        body_format: json
        body:
          name: "My Credential"
          credential_type: 1
          organization: 1
          inputs:
            username: "admin"
            password: "secret"
        status_code: [200, 201]
      register: result
      failed_when: result.status not in [200, 201, 400]
      # 400 = already exists, which is fine (idempotent)
```

**API endpoints to validate per service:**

| Service | Validate Endpoint | What to Check |
|:--------|:------------------|:--------------|
| AAP controller | GET /api/controller/v2/ping/ | Status 200 = healthy |
| AAP credentials | GET /api/controller/v2/credentials/?name=X | count > 0 |
| AAP credential types | GET /api/controller/v2/credential_types/?name=X | count > 0 |
| AAP job templates | GET /api/controller/v2/job_templates/?name=X | count > 0 |
| AAP workflows | GET /api/controller/v2/workflow_job_templates/?name=X | count > 0 |
| AAP inventory sources | GET /api/controller/v2/inventory_sources/?name=X | count > 0 |
| AAP projects | GET /api/controller/v2/projects/?name=X | count > 0, status=successful |
| Vault health | GET /v1/sys/health | initialized=true, sealed=false |
| Vault secret | GET /v1/secret/data/X | data present |
| Vault auth methods | GET /v1/sys/auth | method listed |
| Vault policies | GET /v1/sys/policies/acl/X | policy exists |
| TFE workspaces | GET /api/v2/organizations/ORG/workspaces | workspace found |
| TFE workspace vars | GET /api/v2/workspaces/ID/vars | vars present |
| OPA policy | POST /v1/data/PATH | result.allow = true/false |
| NetBox objects | GET /api/ipam/vlans/?vid=X | count > 0 |

**Generation logic:**

When running `validate-lab` on a lab that has AAP and other API services:
1. Read `.foundry.yml` to identify configured services
2. Read `content/modules/ROOT/pages/` to identify what students create in each module
3. For each module, generate a validation.yml that checks the expected end state
4. For each module, generate a solve.yml that creates the expected end state via API
5. Mark scripts as API-driven in `.foundry.yml` so runtime-automation/main.yml
   knows to run them with `ansible-playbook` instead of `sh`

### Stage 7: health
Generate provisioning health check scripts.

This is the stage Alex W requested. It generates a health check script that:
1. Runs after provisioning completes
2. Checks every service defined in ui-config.yml is accessible
3. Checks every VM/container is running
4. Reports results via webhook (Slack, Mattermost, or custom)
5. Exits non-zero if any critical check fails

**Generated file: utilities/health-check.sh**
```bash
#!/bin/bash
# Auto-generated by Lab Foundry
# Run after provisioning to verify lab health

WEBHOOK_URL="${HEALTH_WEBHOOK_URL:-}"
LAB_NAME="<lab_name>"
GUID="${GUID:-unknown}"
RESULTS=()
FAILURES=0

check_service() {
    local name="$1" url="$2" expected_code="${3:-200}"
    local code=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 10 "$url" 2>/dev/null)
    if [ "$code" = "$expected_code" ]; then
        RESULTS+=("PASS: $name ($url) - HTTP $code")
    else
        RESULTS+=("FAIL: $name ($url) - expected $expected_code, got $code")
        ((FAILURES++))
    fi
}

check_port() {
    local name="$1" host="$2" port="$3"
    if timeout 5 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        RESULTS+=("PASS: $name ($host:$port) - port open")
    else
        RESULTS+=("FAIL: $name ($host:$port) - port closed")
        ((FAILURES++))
    fi
}

# Generated checks from ui-config.yml and instances.yaml
# (Lab Foundry fills these in based on the lab's config)

report_results() {
    local status="SUCCESS"
    [ "$FAILURES" -gt 0 ] && status="FAILED ($FAILURES failures)"

    local report="Lab Health Report: $LAB_NAME (GUID: $GUID)\nStatus: $status\n"
    for r in "${RESULTS[@]}"; do
        report+="  $r\n"
    done

    echo -e "$report"

    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"$report\", \"lab\": \"$LAB_NAME\", \"guid\": \"$GUID\", \"status\": \"$status\", \"failures\": $FAILURES}" \
            2>/dev/null
    fi
}

# Run all checks
# (Generated per-service checks go here)

report_results
exit $FAILURES
```

**Integration with setup-automation:**
Add a task at the end of setup-automation/main.yml that runs the health check:
```yaml
- name: Run provisioning health check
  ansible.builtin.script: "{{ lookup('env', 'MODULE_DIR') }}/../utilities/health-check.sh"
  environment:
    HEALTH_WEBHOOK_URL: "{{ health_webhook_url | default('') }}"
    GUID: "{{ lookup('env', 'GUID') | default('unknown') }}"
  register: health_result
  failed_when: false

- name: Display health check results
  ansible.builtin.debug:
    msg: "{{ health_result.stdout }}"
```

## Skip Configuration

Create or read `.foundry-skip` in the lab root:
```yaml
skip:
  - catalog    # No AgnosticV catalog yet
  - ftl        # Solve/validate not written yet
  - health     # Not ready for health reporting
```

## Output

Display results as a table:
```
Lab Validation Report: zt-ans-bu-cert-lifecycle
================================================
  structure:  PASS (11/11 checks)
  config:     PASS (8/8 checks)
  content:    PASS (delegated to showroom:verify-content)
  automation: WARN (setup scripts missing retry logic in 2 scripts)
  catalog:    SKIP (configured in .foundry-skip)
  ftl:        SKIP (configured in .foundry-skip)
  health:     GENERATED (utilities/health-check.sh created)
================================================
Overall: PASS with 1 warning
```
