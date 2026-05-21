---
name: foundry:forge-lab
description: Scaffold a new RHDP lab from scratch. Creates the complete repo structure (zero-touch, AgnosticV, or showroom-only) with infrastructure config, setup automation, content skeleton, and validation stubs. Use when asked to "create a new lab", "scaffold a lab", "start a new workshop", "build a zero-touch lab", or "forge a lab".
context: main
model: claude-opus-4-6
---

# Forge Lab - Complete Lab Scaffolding

Create a new RHDP lab repository from scratch. Handles all three lab types and generates the full structure including infrastructure, automation, content, and validation.

## Step 1: Gather Requirements

Ask the user these questions (skip any they've already answered):

1. **What is this lab about?** (one sentence description of the learning objective)
2. **Which lab type?**
   - **Zero-touch**: Full infrastructure + content + automation (most common for hands-on labs)
   - **AgnosticV catalog item**: Lightweight catalog entry referencing a showroom repo
   - **Showroom-only**: Documentation + optional runtime automation (no infrastructure provisioning)
3. **Which product(s)?** Ansible, OpenShift, RHEL, or multi-product
4. **What services need to run?** (e.g., AAP controller, EDA, Splunk, FreeIPA, Gitea, etc.)
5. **How many workshop modules?** (estimate, can add more later)
6. **Target event?** Summit, roadshow, RH1, ongoing catalog, or internal training

## Step 2: Select Blueprint

Based on the answers, select the closest matching blueprint from the blueprints/ directory. If no blueprint matches, start from the base templates.

Available blueprints:
- `ansible-basic`: AAP 2.5 + 2 RHEL nodes + Gitea (most Ansible labs)
- `ansible-eda`: AAP + EDA + Kafka + observability + Mattermost
- `ansible-aiops`: AAP + EDA + RHEL AI + Splunk + dashboard
- `openshift-basic`: OCP cluster + workloads
- `rhel-security`: RHEL nodes + security tools

If the user describes services not in any blueprint, compose from individual service definitions.

## Step 3: Scaffold the Repository

### For Zero-Touch Labs

Create the following structure:
```
{lab_repo_name}/
  config/
    instances.yaml    # Generated from blueprint + user requirements
    networks.yaml     # Default network config
    firewall.yaml     # Firewall rules based on services
  setup-automation/
    main.yml          # Ansible playbook orchestrating setup
    setup-control.sh  # AAP/control node setup (if applicable)
    setup-{host}.sh   # Per-host setup stubs
  runtime-automation/
    main.yml          # Module orchestration
    module-01/        # First module stubs
      setup-control.sh
      solve-control.sh
      validation-control.sh
  content/
    antora.yml
    modules/ROOT/
      nav.adoc
      pages/
        index.adoc    # Lab overview
        01-explore.adoc  # First module stub
  site.yml
  default-site.yml
  ui-config.yml       # Showroom UI with tabs for all services
  .foundry.yml        # Lab Foundry metadata (lab type, blueprint, services)
  .foundry-skip       # Default skip config for validation
  README.md
```

### For AgnosticV Catalog Items

Create:
```
{catalog_item_name}/
  common.yaml         # env_type, cloud_provider, git references
  dev.yaml            # Dev deployment config
  test.yaml           # Staging config
  prod.yaml           # Production config
  description.adoc    # Catalog description
  .foundry.yml
```

### For Showroom-Only Labs

Create:
```
{lab_repo_name}/
  content/
    antora.yml
    modules/ROOT/
      nav.adoc
      pages/
        index.adoc
  runtime-automation/  # Optional, create if user wants solve/validate
    main.yml
  site.yml
  ui-config.yml
  .foundry.yml
  README.md
```

## Step 4: Generate Infrastructure Config

For zero-touch labs, generate config/instances.yaml based on the selected blueprint and user requirements.

Key conventions:
- Control node: base-zero-aap-2.5-container-ce image, 16GB RAM, 4 cores
- RHEL nodes: rhel93 image, 4GB RAM, 2 cores
- Containers: specify image, ports, environment, volumes
- Routes: TLS Edge termination for web UIs
- Gitea: always include for SCM (docker.io/gitea/gitea:1.16.8-rootless)
- Firewall: default deny egress, explicit ingress for service ports

## Step 5: Generate Setup Automation

Generate setup scripts with these conventions:
- main.yml: Uses `BASTION_HOST`, `BASTION_USER`, `BASTION_PASSWORD` environment variables
- setup-control.sh: Configures AAP controller (if applicable) with:
  - Wait-for-ready checks (poll controller API before configuring)
  - Retry logic (3 retries with 10s delay for API calls)
  - `ansible.controller` collection modules for resources
  - Idempotent operations
- setup-{host}.sh: Per-host configuration

## Step 6: Generate Content Skeleton

Create Antora content structure with:
- antora.yml with lab metadata
- nav.adoc with module listing
- index.adoc with lab overview (title, objectives, architecture diagram placeholder)
- One .adoc file per module (numbered: 01-explore.adoc, 02-configure.adoc, etc.)
- Module stubs include: title, objectives, steps placeholder, validation section

If the showroom:create-lab skill is available, offer to delegate content generation:
"Want me to generate detailed content for each module? I'll use the showroom:create-lab skill."

## Step 7: Generate Validation Stubs

Create runtime-automation module directories with:
- setup-control.sh: Module-specific setup
- solve-control.sh: Solution script (empty stub with comment)
- validation-control.sh: Validation script (empty stub with comment)

If the ftl:rhdp-lab-validator skill is available, offer to generate full solve/validate:
"Want me to generate solve and validate playbooks? I'll use the FTL lab validator skill."

## Step 8: Generate .foundry.yml Metadata

Create a metadata file that tracks what Lab Foundry knows about this lab:
```yaml
lab_type: zero-touch  # or agnosticv or showroom-only
blueprint: ansible-eda  # which blueprint was used
product: ansible
services:
  - name: control
    type: vm
    role: aap-controller
  - name: gitea
    type: container
    role: scm
modules:
  - id: 01
    title: Explore the Environment
    status: stub
validation:
  webhook_url: ""  # Set to receive provisioning health reports
  skip:
    - catalog  # No AgnosticV catalog yet
```

## Step 9: Initialize Git

```bash
cd {lab_repo_name}
git init
git add -A
git commit -m "Initial lab scaffold from Lab Foundry ({blueprint} blueprint)"
```

Offer to create a GitHub repo:
"Want me to create a GitHub repo? I'll use `gh repo create`."

## Step 10: Summary

Display what was created:
- Lab type and blueprint used
- Services configured (with ports)
- Modules created
- What to do next (add content, configure infrastructure, set up catalog)
- Available foundry skills for next steps

## Important Notes

- NEVER generate complete lab content in this skill. Scaffold stubs, then delegate to showroom:create-lab for actual content.
- ALWAYS use the naming convention: zt-{product_prefix}-{description} for zero-touch labs
- ALWAYS include .foundry.yml for tracking lab metadata
- Setup scripts MUST include wait-for-ready and retry logic
- Firewall rules MUST default to deny-all egress with explicit whitelist
