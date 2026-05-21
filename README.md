# RHDP Lab Foundry

Claude Code plugin for forging Red Hat Demo Platform labs. Scaffolds, configures, validates, and deploys zero-touch labs, AgnosticV catalog items, and Showroom workshops.

## What It Does

Lab Foundry is an orchestrator that composes with the existing RHDP Skills Marketplace. It adds the scaffolding, infrastructure design, and provisioning health reporting layers that are currently missing.

```
/foundry:forge-lab     Scaffold a complete lab from a blueprint
/foundry:add-service   Add a VM, container, or route to a lab
/foundry:add-module    Add a workshop module with content stubs
/foundry:configure-infra   Interactive infrastructure designer
/foundry:validate-lab  Validate structure, config, content + generate health checks
/foundry:add-grading   Generate solve/validate scripts for lab modules
/foundry:deploy-lab    Prepare for RHDP deployment (AgnosticV catalog)
```

## Why

- 60+ labs at Summit 2026, 100+ contributors, 1500 hands-on experiences per day
- Lab creators struggle with infrastructure config (instances.yaml, firewall rules)
- Setup scripts fail silently with no visibility into what broke
- No unified tool goes from "I need a lab" to a deployable repo
- Existing RHDP skills handle content and catalog, but not infrastructure scaffolding

## Install

```bash
# Add the Lab Foundry marketplace
/plugin marketplace add anshulbehl/rhdp-lab-foundry

# Install the plugin
/plugin install foundry@rhdp-lab-foundry

# Also install RHDP skills (Lab Foundry delegates to these)
/plugin marketplace add rhpds/rhdp-skills-marketplace
/plugin install showroom@rhdp-marketplace
/plugin install agnosticv@rhdp-marketplace
/plugin install health@rhdp-marketplace
```

## Quick Start

```
# Scaffold a new Ansible AIOps lab
/foundry:forge-lab

# Add Splunk to an existing lab
/foundry:add-service

# Validate the lab and generate health check scripts
/foundry:validate-lab

# Prepare for RHDP deployment
/foundry:deploy-lab
```

## Blueprints

Pre-built lab configurations:

| Blueprint | Products | Resources |
|:----------|:---------|:----------|
| ansible-basic | AAP + 2 RHEL + Gitea | 28GB, 8 cores |
| ansible-eda | AAP + EDA + Kafka + Mattermost | 32GB, 10 cores |
| ansible-aiops | AAP + EDA + RHEL AI + Splunk + Mattermost | 40GB, 10 cores |
| openshift-basic | OCP cluster + workloads | varies |
| rhel-security | RHEL + security tools | 12GB, 6 cores |

## Health Reporting

Lab Foundry generates provisioning health check scripts that:
1. Verify every service is accessible after provisioning
2. Check all ui-config.yml tabs are reachable
3. Report results via webhook (Slack, Mattermost, or custom endpoint)
4. Surface failures immediately instead of waiting for user reports

This addresses the #1 pain point reported by lab facilitators: not knowing when provisioning silently fails.

## Lab Types Supported

- **Zero-touch labs** (zt-*): Full infrastructure + content + automation
- **AgnosticV catalog items**: Lightweight catalog entries referencing showroom repos
- **Showroom-only**: Documentation + optional runtime automation
