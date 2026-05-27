---
name: foundry:forge-lab
description: Scaffold a new RHDP lab from scratch. Creates the complete repo structure (zero-touch, AgnosticV, or showroom-only) with infrastructure config, setup automation, content skeleton, and validation stubs. Use when asked to "create a new lab", "scaffold a lab", "start a new workshop", "build a zero-touch lab", or "forge a lab".
context: main
model: claude-opus-4-6
---

# Forge Lab - Complete Lab Scaffolding

Create a new RHDP lab repository from scratch.

## Format Rules

→ All config format rules: `@foundry/skills/forge-lab/references/config-format-rules.md`

Read this file before generating any config files. It contains the
exact formats required by the RHDP runner.

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

For each file, READ the template first, then modify only what's needed.

### 4a. Copy these files exactly (read then write, no changes):

→ Read `@foundry/skills/forge-lab/templates/networks.yaml` and write to `config/networks.yaml`
→ Read `@foundry/skills/forge-lab/templates/ansible.cfg` and write to `setup-automation/ansible.cfg`
→ Read `@foundry/skills/forge-lab/templates/requirements.yml` and write to `setup-automation/requirements.yml`
→ Read `@foundry/templates/zero-touch/config/secrets.yaml` and write to `config/secrets.yaml`

### 4b. Copy structure, modify for this lab:

→ Read `@foundry/skills/forge-lab/templates/instances-aap-basic.yaml`
  Write to `config/instances.yaml`, adjusting VM names and count only.
  Keep ALL patterns: tags key/value, networks, userdata, CA cert, ports list.

→ Read `@foundry/skills/forge-lab/templates/firewall.yaml`
  Write to `config/firewall.yaml`, adding ports for additional services.

→ Read `@foundry/skills/forge-lab/templates/main.yml`
  Write to `setup-automation/main.yml`, adjusting host list if needed.

→ Read `@foundry/skills/forge-lab/templates/setup-control.sh`
  Write to `setup-automation/setup-control.sh`, adjusting collections if needed.

→ Read `@foundry/skills/forge-lab/templates/setup-control-configure.sh`
  Write to `setup-automation/setup-control-configure.sh`.
  Modify ONLY the inline playbook tasks for this lab's AAP resources.
  Keep module_defaults, validate_certs, env var exports exactly as template.

→ Read `@foundry/skills/forge-lab/templates/runtime-main.yml`
  Write to `runtime-automation/main.yml`. Required for Showroom
  solve/validate buttons. Do not modify.

**Runtime automation scripts** go in `runtime-automation/module-NN/`:
- Name scripts as `solve-control.sh` and `validation-control.sh`
  (matching the bastion hostname `control`), NOT `solve-host1.sh`.
- Make all scripts executable.

**content/antora.yml** MUST use `name: modules` (not the lab name).
Showroom expects content at `/modules/` path. If you use any other
name, Showroom returns 404.

### 4c. Generate from scratch:

- `ui-config.yml` - tabs with `external: false`, trailing slash on URLs
- `site.yml` / `default-site.yml` - Antora config with nookbag theme
- `content/antora.yml`, `nav.adoc`, module pages
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
