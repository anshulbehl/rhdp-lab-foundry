---
name: foundry:forge-lab
description: Scaffold a new RHDP lab from scratch. Creates the complete repo structure (zero-touch, AgnosticV, or showroom-only) with infrastructure config, setup automation, content skeleton, and validation stubs. Use when asked to "create a new lab", "scaffold a lab", "start a new workshop", "build a zero-touch lab", or "forge a lab".
context: main
model: claude-opus-4-6
---

# Forge Lab - Complete Lab Scaffolding

Create a new RHDP lab repository from scratch.

## Step 0: Load Templates and Rules (MANDATORY)

BEFORE doing anything else, read ALL of these files:

1. `@forge-lab/references/config-format-rules.md` - All format rules
2. `@forge-lab/templates/networks.yaml` - Copy exactly
3. `@forge-lab/templates/firewall.yaml` - Copy structure
4. `@forge-lab/templates/ansible.cfg` - Copy exactly
5. `@forge-lab/templates/requirements.yml` - Copy exactly
6. `@forge-lab/templates/instances-aap-basic.yaml` - Copy structure
7. `@forge-lab/templates/setup-control.sh` - Copy structure
8. `@forge-lab/templates/setup-control-configure.sh` - Copy structure
9. `@forge-lab/templates/main.yml` - Copy structure
10. `../../templates/zero-touch/config/secrets.yaml` - Copy exact bytes

These templates are your source of truth. When generating files, READ
the template first, then modify only the parts that need to change for
the specific lab. Do NOT generate from memory or from rules text.

## Step 1: Interview (5 Phases)

Run the interview to gather requirements. Skip questions the user has
already answered. Use AskUserQuestion with appropriate options.

### Phase 1: Identity and Purpose

1. **What is this lab about?** (free text, one sentence)
2. **Which lab type?** Zero-touch | AgnosticV | Showroom-only
3. **Which product family?** Ansible | OpenShift | RHEL | Multi-product
4. **Target audience?** Customers | Partners | Internal | Developer
5. **Target event?** Summit | Red Hat One | Roadshow | Catalog | Training | Demo

### Phase 2: Platform and Infrastructure

6. **Infrastructure backend?** OpenShift CNV (default) | AWS EC2 | Docs-only
7. **AAP version?** AAP 2.6 (image: aap-2.6-6-ceh-20260325, recommended) | AAP 2.5
8. **RHEL version?** RHEL 9.5 (image: rhel-9.5, recommended) | RHEL 10.0 | RHEL 10.1
9. **Managed nodes?** 0 | 1 | 2 | 3 | 4+
10. **Windows nodes?** No | 1 | 2
11. **Network devices?** No | Arista cEOS | Cisco | Both

### Phase 3: Services and Integrations

12. **SCM/Git?** Gitea (recommended) | None
13. **EDA?** No | Yes with Kafka | Yes webhooks only
14. **Observability?** None | Prometheus+Alertmanager | Splunk | Dynatrace | Instana
15. **ChatOps?** None | Mattermost | Slack
16. **AI/LLM?** No | RHEL AI | External API | Both
17. **Identity provider?** No | FreeIPA container | FreeIPA VM | Keycloak | Self-signed
18. **Database?** No | PostgreSQL | MySQL
19. **Dashboard?** No | Custom FastAPI | Grafana
20. **HashiCorp?** No | Vault | Terraform Enterprise | Both
21. **Student IDE?** No | VSCode code-server
22. **Policy-as-code?** No | OPA | OPA + SPIFFE/SPIRE
23. **CMDB?** No | NetBox
24. **Other services?** (free text)

### Phase 4: Content and Workshop Structure

25. **Module count?** 1-2 | 3-5 | 6-8 | 9+
26. **Structure?** Guided | Exploratory | Mixed
27. **Grading?** No | Shell script | Ansible FTL | API-driven | Both
28. **Remote Desktop?** No | IronRDP | noVNC
29. **Cloud credentials?** None | AWS | Azure | Both | GCP

### Phase 5: Operational Details

30. **AAP post-install?** No (students configure) | Yes full | Yes partial
31. **Duration?** 45min | 60min | 90min | 2+hours | Self-paced
32. **Lifespan?** 45min | 1h | 2h | 4h | 8h
33. **Multi-user?** Single (default) | Multiple
34. **LiteMaaS?** No | Yes
35. **Health webhook?** No | Slack | Mattermost | Custom

### Smart Defaults

- RHEL product: skip AAP, EDA, ChatOps, AI/LLM
- Showroom-only: skip Phase 2 and 3
- Summit: 45-min duration, 45-min lifespan
- Internal: 2-hour duration, 4-hour lifespan

## Step 2: Load References

After interview, check answers against `foundry/references/INDEX.md` tags.
Load matching reference files for architecture guidance.

## Step 3: Summarize and Confirm

Show the user a summary table. Ask for confirmation before scaffolding.

## Step 4: Generate Files (TEMPLATE-FIRST)

For each file, the process is:
1. READ the template file
2. MODIFY only the parts specific to this lab
3. WRITE to the target directory
4. READ BACK to verify format

### Files to generate:

**Copy exactly (no modifications):**
- `config/networks.yaml` - from `@forge-lab/templates/networks.yaml`
- `config/secrets.yaml` - from `../../templates/zero-touch/config/secrets.yaml`
- `setup-automation/ansible.cfg` - from `@forge-lab/templates/ansible.cfg`
- `setup-automation/requirements.yml` - from `@forge-lab/templates/requirements.yml`

**Copy structure, modify for lab:**
- `config/instances.yaml` - from `@forge-lab/templates/instances-aap-basic.yaml`
  - Adjust VM count, names, cores/memory
  - Keep ALL format patterns (tags, networks, userdata, CA cert, ports)
- `config/firewall.yaml` - from `@forge-lab/templates/firewall.yaml`
  - Add ports for additional services
- `setup-automation/main.yml` - from `@forge-lab/templates/main.yml`
  - Adjust host list if needed
- `setup-automation/setup-control.sh` - from `@forge-lab/templates/setup-control.sh`
  - Adjust requirements.yml collection list if needed
- `setup-automation/setup-control-configure.sh` - from `@forge-lab/templates/setup-control-configure.sh`
  - Modify inline playbook tasks for this lab's resources
  - Keep module_defaults, validate_certs, env vars exactly as template

**Generate from scratch:**
- `ui-config.yml` - tabs with `external: false`, trailing slash on URLs
- `site.yml` / `default-site.yml` - Antora config with nookbag theme
- `content/antora.yml` - component descriptor
- `content/modules/ROOT/nav.adoc` - navigation
- `content/modules/ROOT/pages/*.adoc` - module content
- `.foundry.yml` - interview answers
- `runtime-automation/module-NN/` - solve/validate stubs

## Step 5: Post-Scaffolding Validation (MANDATORY)

After generating ALL files, run these checks. Fix any failures
BEFORE reporting success to the user.

1. **Read `config/networks.yaml`**: First non-comment line after `---`
   must be `- name:`. If it starts with `networks:`, rewrite the file.

2. **Read `config/instances.yaml`**: Verify:
   - AAP image is exactly `aap-2.6-6-ceh-20260325`
   - VM memory uses `G` not `Gi`
   - Every VM has `networks:`, `tags:` (key/value format), `userdata: |-`
   - AAP route has `tls_destinationCACertificate`
   - Service ports use `ports:` list format with `name` field

3. **Read `config/secrets.yaml`**: First line must be `username: !vault`.
   If it says `secrets:` or is empty, copy from template again.

4. **Read `setup-automation/setup-control-configure.sh`**: Verify:
   - Does NOT have `set -euo pipefail`
   - Uses `https://localhost` (not port 8443)
   - Has `module_defaults` with `validate_certs: false`
   - Credential username matches VM userdata user

5. **Content consistency**: Every hostname in content matches instances.yaml.

Report validation results:
```
Scaffolding complete for [lab_name]:
  config/          [5 files] - validated
  setup-automation/ [5 files] - validated
  content/         [N modules] - generated
  [auto-fixed: 0 issues]
```

## Container Route Behavior

Containers work on both Developer Experience CI and AgnosticV production.
Always include container definitions with services and routes sections.

## Cross-Layer Consistency

When infrastructure changes, update ALL layers:
- instances.yaml hosts must match content page references
- Credential username/password must match VM userdata
- Validation scripts check only for resources content describes

## Important Notes

- NEVER skip the interview
- For each question, show the recommended option first
- If user references an existing lab, read its .foundry.yml to pre-populate
- Save all answers to .foundry.yml for future reference
