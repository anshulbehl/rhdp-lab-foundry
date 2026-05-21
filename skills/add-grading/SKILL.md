---
name: foundry:add-grading
description: Generate solve and validate scripts for lab modules. Creates shell scripts or Ansible playbooks that automate what students do (solve) and verify they did it correctly (validate). Delegates to ftl:rhdp-lab-validator when available. Use when asked to "add grading", "add solve/validate", "add testing", "generate validation scripts", or "add E2E testing".
context: main
model: claude-sonnet-4-6
---

# Add Grading - Generate Solve and Validate Scripts

Creates solve (solution) and validate (verification) scripts for lab modules.

## Two Approaches

### Shell Script Grading (Traditional)
Simple bash scripts in runtime-automation/module-NN/:
- `solve-control.sh`: Automates what the student should do
- `validation-control.sh`: Checks if the student did it correctly (exit 0 = pass, exit 1 = fail)

### Ansible Grading (FTL)
Ansible playbooks using the Full Test Lifecycle framework:
- `solve.yml`: Ansible playbook that automates the solution
- `validate.yml`: Ansible playbook that verifies the result

## Workflow

1. Read the content module (.adoc) to understand what students do
2. Ask: Shell scripts or Ansible playbooks?
3. Generate the scripts/playbooks
4. If ftl:rhdp-lab-validator is available, offer to delegate:
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
