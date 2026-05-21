---
name: foundry:forge-lab
description: Scaffold a new RHDP lab from scratch. Creates the complete repo structure (zero-touch, AgnosticV, or showroom-only) with infrastructure config, setup automation, content skeleton, and validation stubs. Use when asked to "create a new lab", "scaffold a lab", "start a new workshop", "build a zero-touch lab", or "forge a lab".
context: main
model: claude-opus-4-6
---

# Forge Lab - Complete Lab Scaffolding

Create a new RHDP lab repository from scratch. Handles all three lab types and generates the full structure including infrastructure, automation, content, and validation.

## Interview Process

The interview is organized into 5 phases. Each phase builds on the previous one. Skip questions the user has already answered. Use AskUserQuestion with appropriate options for each.

### Phase 1: Identity and Purpose

These questions determine the lab type and blueprint.

1. **What is this lab about?**
   Free text. One sentence describing the learning objective.
   Example: "Teach operators how to use AI-driven certificate lifecycle management with Ansible"

2. **Which lab type?**
   Options:
   - Zero-touch (hands-on lab with full infrastructure provisioning)
   - AgnosticV catalog item (catalog entry referencing an existing showroom repo)
   - Showroom-only (documentation with optional grading, no infrastructure provisioning)

3. **Which product family?**
   Options:
   - Ansible Automation Platform
   - OpenShift
   - RHEL
   - Multi-product (specify which)

4. **Target audience?**
   Options:
   - Customers (external hands-on lab)
   - Partners (partner enablement)
   - Internal (field enablement, TMM training)
   - Developer (contributor/developer onboarding)

5. **Target event or use?**
   Options:
   - Red Hat Summit
   - Red Hat One / regional events
   - Roadshow
   - Ongoing RHDP catalog item
   - Internal training only
   - One-time demo

### Phase 2: Platform and Infrastructure

These questions determine the deployment platform and base infrastructure.

6. **Infrastructure backend?**
   Options:
   - OpenShift CNV (default for RHDP labs, KVM VMs on OpenShift)
   - AWS EC2 (cloud VMs, requires cloud credentials)
   - Documentation only (no infrastructure needed)

7. **AAP version?** (only if product is Ansible)
   Options:
   - AAP 2.5 (current GA, image: base-zero-aap-2.5-container-ce)
   - AAP 2.6 (latest, image: base-zero-aap-2.6-container-ce)
   - No AAP (RHEL-only lab)

8. **RHEL version for managed nodes?**
   Options:
   - RHEL 9.3 (image: rhel93)
   - RHEL 9.4 (image: rhel-9.4)
   - RHEL 10.0 (image: rhel-10-0-07-09-25-3)
   - RHEL 10.1 (image: rhel-10-1-04-15-26)
   - Not applicable

9. **How many managed nodes (RHEL VMs)?**
   Options: 0, 1, 2, 3, 4+

10. **Need Windows nodes?**
    Options:
    - No
    - Yes, 1 Windows Server
    - Yes, 2 Windows Servers

11. **Need network devices?** (routers, switches)
    Options:
    - No
    - Arista (cEOS containers)
    - Cisco (IOSv or CSR containers)
    - Both

### Phase 3: Services and Integrations

These questions determine which containers and services to deploy.

12. **Which SCM/Git service?**
    Options:
    - Gitea (default, lightweight, recommended)
    - None (use external GitHub)

13. **Need Event-Driven Ansible (EDA)?**
    Options:
    - No
    - Yes, with Kafka event bus
    - Yes, with webhook sources only (no Kafka)

14. **Observability/monitoring integration?**
    Options (multi-select):
    - None
    - Prometheus + Alertmanager
    - Splunk (with HEC)
    - Dynatrace
    - IBM Instana
    - Custom (specify)

15. **ChatOps/notification platform?**
    Options:
    - None
    - Mattermost (container, self-hosted)
    - Slack (external, webhook only)

16. **Need an AI/LLM endpoint?**
    Options:
    - No
    - RHEL AI with Granite model (VM, 16GB+ RAM, GPU recommended)
    - External LLM via API (litellm proxy, OpenAI-compatible)
    - Both (local Granite + external fallback)

17. **Need a certificate authority?**
    Options:
    - No
    - FreeIPA/IDM (container)
    - Self-signed certs only

18. **Need a database?**
    Options:
    - No
    - PostgreSQL (container)
    - MySQL/MariaDB (container)

19. **Need a dashboard/web app?**
    Options:
    - No
    - Custom dashboard (Python FastAPI + HTML)
    - Grafana (container)

20. **Any other services?** (free text)
    Let the user describe additional services not covered above.

### Phase 4: Content and Workshop Structure

21. **How many workshop modules?**
    Options: 1-2, 3-5, 6-8, 9+

22. **Module structure?**
    Options:
    - Guided (step-by-step instructions with copy-paste commands)
    - Exploratory (objectives given, students figure out the approach)
    - Mixed (some guided, some exploratory)

23. **Need solve/validate grading?**
    Options:
    - No (documentation only)
    - Shell script grading (traditional setup/solve/validation scripts)
    - Ansible grading (FTL framework with solve.yml/validate.yml)
    - Both

24. **Need a Remote Desktop (RDP)?**
    Options:
    - No
    - Yes, IronRDP for Windows access
    - Yes, noVNC for Linux desktop

25. **Cloud provider credentials for students?**
    Options:
    - None needed
    - AWS credentials
    - Azure credentials
    - AWS and Azure
    - GCP credentials

### Phase 5: Operational Details

26. **Lab duration?**
    Options:
    - 45 minutes
    - 60 minutes (1 hour)
    - 90 minutes
    - 2+ hours
    - Self-paced (no time limit)

27. **Lab lifespan (how long should provisioned instances stay up)?**
    Options:
    - 45 minutes (default for events)
    - 1 hour
    - 2 hours
    - 4 hours
    - 8 hours (full day)

28. **Multi-user support?**
    Options:
    - Single user per instance (default)
    - Multiple users sharing one cluster (OCP labs)

29. **LiteMaaS integration?** (for GPU/AI workloads)
    Options:
    - No
    - Yes (requires LiteMaaS API keys in AgnosticV includes)

30. **Provisioning health webhook?**
    Options:
    - No
    - Slack channel (provide channel webhook URL)
    - Mattermost (provide webhook URL)
    - Custom endpoint (provide URL)

## Smart Defaults

Not every question needs to be asked. Use these rules to skip or auto-answer:

- If product is **RHEL** (not Ansible): skip AAP version, EDA, ChatOps, AI/LLM
- If lab type is **showroom-only**: skip all infrastructure questions (Phase 2 and 3)
- If lab type is **agnosticv**: skip infrastructure details (they come from the referenced repo)
- If target is **internal training**: default to 2-hour duration, 4-hour lifespan
- If target is **Summit**: default to 45-min duration, 45-min lifespan
- If **no EDA**: skip Kafka and observability questions
- If **no AAP**: skip AAP version question
- If infrastructure is **docs-only**: skip all service questions

## After Interview

1. Summarize the selections back to the user in a clear table
2. Ask for confirmation before scaffolding
3. Select the closest blueprint and customize it
4. Generate the complete repo structure
5. Show what was created and what to do next

## Blueprint Selection Logic

```
if product == ansible:
    if has_eda and has_ai:
        blueprint = ansible-aiops
    elif has_eda:
        blueprint = ansible-eda
    else:
        blueprint = ansible-basic
elif product == openshift:
    blueprint = openshift-basic
elif product == rhel:
    blueprint = rhel-security
else:
    blueprint = None (build from scratch using service definitions)
```

## Scaffolding

After interview and confirmation, create the repo structure as documented in the original skill definition. The key additions from the interview:

1. **instances.yaml**: Generated from blueprint + answers to Phase 2/3 questions
2. **firewall.yaml**: Ports derived from selected services
3. **ui-config.yml**: Tabs for each service with a web UI
4. **setup-automation/setup-control.sh**: AAP version-specific setup using `ansible.controller` modules
5. **.foundry.yml**: Records all interview answers for future reference
6. **utilities/health-check.sh**: Generated if webhook URL provided (Phase 5, Q30)

## Important Notes

- NEVER skip the interview. The exhaustive question set is what makes this tool valuable.
- For each question, show the recommended/default option first.
- Group questions logically, don't ask all 30 at once. Use 5 phases.
- If the user says "just like the EDA lab" or references an existing lab, read that lab's .foundry.yml or config/ to pre-populate answers.
- Save all answers to .foundry.yml so the lab can be rebuilt or modified later.
