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
   This becomes the lab title and drives blueprint selection.
   Example: "Teach operators how to use AI-driven certificate lifecycle management with Ansible"

2. **Which lab type?**
   This determines the entire repo structure and what gets generated.
   Options:
   - Zero-touch: Self-contained repo with infrastructure, automation, AND content. RHDP provisions everything from config/instances.yaml. Choose this for hands-on labs where students need dedicated VMs and services.
   - AgnosticV catalog item: Lightweight catalog entry inside an AgnosticV repo. Points to a separate Showroom repo for content. Choose this when infrastructure already exists and you just need a catalog listing.
   - Showroom-only: Documentation and optional runtime automation only. No VMs or containers are provisioned. Choose this when students use a shared cluster or external infrastructure.

3. **Which product family?**
   Determines which blueprints are available and what default services get included.
   Options:
   - Ansible Automation Platform: Labs focused on AAP controller, EDA, Lightspeed, or automation workflows. Includes an AAP controller VM by default.
   - OpenShift: Labs focused on OCP, operators, or containerized workloads. Assumes a shared OCP cluster, no VMs provisioned.
   - RHEL: Labs focused on system administration, security, or OS-level tasks. Uses plain RHEL VMs without AAP.
   - Multi-product: Labs spanning multiple products (e.g., AAP + OpenShift, RHEL + Satellite). Specify which products so the right services are included.

4. **Target audience?**
   Affects content tone, complexity level, and default duration settings.
   Options:
   - Customers: External hands-on lab at events or in the RHDP catalog. Content should be polished, self-explanatory, and assume no prior Red Hat experience.
   - Partners: Partner enablement sessions. Can assume some Red Hat familiarity but should still be well-documented.
   - Internal: Field enablement, TMM training, or internal demos. Can assume deep product knowledge and use internal terminology.
   - Developer: Contributor or developer onboarding. Focuses on development workflows, testing, and CI/CD patterns.

5. **Target event or use?**
   Affects default duration, lifespan, resource allocation, and validation requirements.
   Options:
   - Red Hat Summit: High-visibility event lab. Requires validation scripts, health checks, and tight resource limits (45-min sessions, hundreds of concurrent users).
   - Red Hat One / regional events: Regional events with moderate scale. Similar to Summit but with more flexibility on duration.
   - Roadshow: Traveling workshop delivered by field teams. Needs to be reliable and well-tested since the presenter may not be the author.
   - Ongoing RHDP catalog item: Always-available lab in the RHDP catalog. Needs long-term maintenance, versioned content, and robust error handling.
   - Internal training only: Not customer-facing. Can cut corners on polish but should still work reliably.
   - One-time demo: Single-use demonstration. Minimal validation needed, prioritize speed of development.

### Phase 2: Platform and Infrastructure

These questions determine the deployment platform and base infrastructure.

6. **Infrastructure backend?**
   Where will the lab's VMs and containers run? Most RHDP labs use OpenShift CNV.
   Options:
   - OpenShift CNV: Default for RHDP zero-touch labs. KVM virtual machines run on OpenShift. This is what the RHDP runner provisions. Choose this unless you have a specific reason not to.
   - AWS EC2: Cloud VMs provisioned in AWS. Requires AWS credentials in the lab config. Use for labs that need AWS-specific features (VPCs, S3, IAM) or larger instances than CNV supports.
   - Documentation only: No infrastructure provisioned. The lab is pure content. Choose this for showroom-only labs or labs using shared infrastructure.

7. **AAP version?** (only if product is Ansible)
   Determines the controller VM image and which features are available (e.g., 2.6 adds Gateway API, OPA integration).
   Options:
   - AAP 2.6: Current release with Gateway API, platform-level OPA policy, and improved EDA. Image: aap-2.6-6-ceh-20260325. This is the proven image used by all Summit 2026 labs.
   - AAP 2.5: Previous GA release. Image: base-zero-aap-2.5-container-ce. May not be available on all RHDP clusters. Use only if your lab specifically requires 2.5.
   - No AAP: RHEL-only lab without an automation controller. For system administration or OS-level labs.

8. **RHEL version for managed nodes?**
   The RHEL version for target VMs that AAP will automate against. Does not affect the controller VM.
   Options:
   - RHEL 9.5 (image: rhel-9.5): Current standard, used by most production labs.
   - RHEL 9.4 (image: rhel-9.4): Newer, use when you need specific 9.4 packages.
   - RHEL 10.0 (image: rhel-10-0-07-09-25-3): For labs showcasing RHEL 10 features.
   - RHEL 10.1 (image: rhel-10-1-04-15-26): Latest RHEL 10.
   - Not applicable: No managed RHEL nodes needed (e.g., network-only or OCP labs).

9. **How many managed nodes (RHEL VMs)?**
   These are the target hosts that AAP will run playbooks against. Each node adds ~4GB RAM and 2 cores to the total.
   Options: 0, 1, 2, 3, 4+

10. **Need Windows nodes?**
    Windows Server VMs that AAP will manage via WinRM. Used for labs demonstrating Windows automation (AD, IIS, patching).
    Options:
    - No: Linux-only lab.
    - Yes, 1 Windows Server: Single Windows target for basic Windows automation exercises.
    - Yes, 2 Windows Servers: Two targets for multi-host Windows scenarios (e.g., AD domain setup).

11. **Need network devices?**
    Virtual network switches/routers for network automation labs. These run as containers simulating real network OS.
    Options:
    - No: No network automation exercises.
    - Arista cEOS: Containerized Arista EOS switches. Supports eAPI, VLAN management, ACLs. Used in the Zero Trust Summit lab for micro-segmentation demos.
    - Cisco IOSv/CSR: Containerized Cisco devices. Supports IOS CLI, NETCONF, RESTCONF.
    - Both: Mixed-vendor network lab for multi-platform automation exercises.

### Phase 3: Services and Integrations

These questions determine which containers and services to deploy alongside the base infrastructure.

12. **Which SCM/Git service?**
    A local Git server for hosting playbooks, roles, and project repos that AAP pulls from. Students push code here instead of GitHub.
    Options:
    - Gitea: Lightweight, self-hosted Git server (container, 512MB). Recommended for most labs. Provides a web UI for students to browse and edit code. Pre-configured with an admin account and lab repositories.
    - None: Students use external GitHub or the lab content is baked into the AAP project configuration. Only choose this if the lab doesn't involve students editing code.

13. **Need Event-Driven Ansible (EDA)?**
    EDA listens for events from external systems and triggers AAP job templates automatically. Used for incident response, self-healing, and real-time automation demos.
    Options:
    - No: Lab doesn't involve event-driven automation.
    - Yes, with Kafka: Full EDA stack with Apache Kafka as the event bus. Use when events come from multiple sources or need guaranteed delivery. Adds a Kafka container (~1GB RAM).
    - Yes, with webhook sources only: EDA listens for HTTP webhooks directly (from Splunk, Dynatrace, ServiceNow, etc.). Simpler setup, no Kafka needed. This is the pattern used in the Zero Trust Summit lab for Splunk-triggered incident response.

14. **Observability/monitoring integration?**
    External monitoring systems that feed data into the lab. These generate events, alerts, or dashboards that students interact with.
    Options (multi-select):
    - None: No monitoring integration.
    - Prometheus + Alertmanager: Metrics collection and alerting. Prometheus scrapes targets, Alertmanager routes alerts to EDA or ChatOps. Good for infrastructure monitoring demos.
    - Splunk (with HEC): Log aggregation via HTTP Event Collector. Students can create saved searches and alerts that trigger EDA. Used in the Zero Trust Summit lab for brute-force detection.
    - Dynatrace: APM platform (external SaaS, webhook integration only). For application performance monitoring demos.
    - IBM Instana: APM platform (external SaaS, webhook integration only). For AI-driven observability demos.
    - Custom: Describe what you need and it will be added to the service definitions.

15. **ChatOps/notification platform?**
    A messaging platform where students can see automation notifications and interact with chatbots.
    Options:
    - None: No chat integration.
    - Mattermost: Self-hosted Slack alternative (container, ~1GB RAM). Students get their own channels. AAP and EDA can post notifications here via webhook.
    - Slack: External Slack workspace (webhook only, no container deployed). Students see notifications in an existing Slack channel. Requires a pre-configured webhook URL.

16. **Need an AI/LLM endpoint?**
    A local or external language model for AI-assisted automation (Lightspeed, AIOps, agentic workflows).
    Options:
    - No: Lab doesn't involve AI features.
    - RHEL AI with Granite model: Dedicated VM (16GB+ RAM, GPU recommended) running IBM Granite locally. Students interact with the model via API. Requires LiteMaaS GPU allocation on RHDP.
    - External LLM via API: A litellm proxy container that forwards requests to OpenAI, Azure OpenAI, or other providers. Lighter weight but requires API keys.
    - Both: Local Granite for the primary exercises, external API as fallback. For labs that demonstrate hybrid AI architectures.

17. **Need a certificate authority or identity provider?**
    Identity and certificate services for authentication, authorization, and TLS certificate management.
    Options:
    - No: Lab uses simple username/password auth, no centralized identity.
    - FreeIPA/IDM (container): Lightweight FreeIPA container for basic certificate authority and LDAP. Good for labs that just need to issue certificates or do simple LDAP lookups. Limited DNS/Kerberos functionality.
    - FreeIPA/IDM (VM): Full Red Hat Identity Management server with DNS, Kerberos, LDAP, and HBAC. Use when the lab needs centralized authentication, IPA client enrollment across nodes, or host-based access control. This is the pattern used in the Zero Trust Summit lab. Often runs on a central node alongside other services.
    - Keycloak: OIDC/SAML identity provider for web application SSO. Use when the lab involves web application authentication, OAuth flows, or federated identity. Can integrate with FreeIPA as a backend.
    - Self-signed certs only: Generate self-signed TLS certificates during setup. Simplest option for labs that just need HTTPS but don't teach identity concepts.

18. **Need a database?**
    A database server for labs involving data management, application deployment, or dynamic credentials.
    Options:
    - No: Lab doesn't need a database.
    - PostgreSQL: Standard relational database (container, ~512MB). Used by many services (NetBox, applications) and by Vault for dynamic credential demos. The Zero Trust lab uses PostgreSQL with Vault-managed short-lived credentials.
    - MySQL/MariaDB: Alternative relational database (container, ~512MB). Choose based on the application stack being taught.

19. **Need a dashboard/web app?**
    A visual dashboard showing lab topology, status, or application state. Gives students a "single pane of glass" view.
    Options:
    - No: No custom dashboard.
    - Custom dashboard (Python FastAPI + HTML): A lightweight web app (container) displaying lab topology, service health, or exercise progress. The Zero Trust lab uses this to show a live network topology diagram.
    - Grafana: Full Grafana instance (container) with pre-configured dashboards. Good for labs that visualize Prometheus metrics or time-series data.

20. **Need HashiCorp products?**
    Enterprise HashiCorp products for secrets management and infrastructure-as-code. These run as dedicated VMs with enterprise licensing.
    Options (multi-select):
    - No: No HashiCorp integration.
    - HashiCorp Vault: Dedicated VM (16GB, 2 cores) for secrets management, dynamic credentials, SSH CA, AppRole authentication, and policy enforcement. Used in both the Zero Trust and HashiCorp Summit labs. Requires a Vault Enterprise license (VAULT_LIC env var).
    - Terraform Enterprise: Dedicated VM (16GB, 4 cores, 120GB disk) for infrastructure-as-code with VCS integration, workspace management, and API-driven runs. This is the pattern from the most popular Summit lab (LB1390). Requires a TFE license (TFE_LIC env var).
    - Both Vault and Terraform Enterprise: Full HashiCorp stack. AAP orchestrates TFE for provisioning and Vault for secret management. The HashiCorp Summit lab demonstrates this end-to-end flow.

21. **Need a student IDE/development environment?**
    A browser-based code editor where students write, test, and commit code. Eliminates the need for students to install anything locally.
    Options:
    - No: Students use the terminal or the AAP web UI only.
    - VSCode code-server: Dedicated VM (8GB, 2 cores) running VS Code in the browser. Pre-installed with cloud CLIs (AWS, Terraform), ansible-builder, and development tools. Students write playbooks, build execution environments, and interact with cloud providers directly. This is the pattern from the HashiCorp Summit lab. Accessible via a Showroom tab.

22. **Need policy-as-code enforcement?**
    Policy engines that evaluate rules before automation runs. Used for compliance, access control, and zero-trust architectures.
    Options:
    - No: No policy enforcement beyond standard AAP RBAC.
    - OPA (Open Policy Agent): Stateless policy engine (container, ~512MB). Can integrate at two levels: playbook-level (tasks call OPA via URI module) or AAP platform-level (AAP 2.6 queries OPA before enqueuing jobs). The Zero Trust lab demonstrates both levels with team-based and action-based policies.
    - OPA + SPIFFE/SPIRE: Policy engine plus workload identity verification. SPIRE issues X.509 certificates with SPIFFE IDs to workloads, and OPA checks both the human user AND the workload identity before allowing actions. This is the "defense in depth" pattern from the Zero Trust lab where even the right user on the wrong workload gets denied.

23. **Need a CMDB/infrastructure source of truth?**
    A configuration management database that tracks infrastructure state. Used for dynamic inventory, compliance, and change management.
    Options:
    - No: No CMDB needed.
    - NetBox: Open-source CMDB with a REST API (container or Docker Compose, ~2GB). Tracks devices, VLANs, IP addresses, and circuits. AAP can use NetBox as a dynamic inventory source and update it after changes. The Zero Trust lab uses NetBox to track VLAN assignments.

24. **Any other services?** (free text)
    Describe any additional services not covered above. Include the service name, what it does in the lab, and whether it needs a web UI tab.
    Examples: "ServiceNow instance for ITSM integration", "AWX for upstream testing", "MinIO for S3-compatible storage".

### Phase 4: Content and Workshop Structure

25. **How many workshop modules?**
    Each module is a self-contained section of the workshop with its own AsciiDoc page and optional runtime automation (setup/solve/validate scripts).
    Options:
    - 1-2: Quick demo or single-topic lab (30-45 minutes).
    - 3-5: Standard workshop covering a focused workflow (60-90 minutes). Most Summit labs fall here.
    - 6-8: Comprehensive workshop with multiple scenarios (2+ hours). The Zero Trust Summit lab has 7 modules.
    - 9+: Multi-day training or self-paced course. Consider splitting into separate labs.

26. **Module structure?**
    How prescriptive are the exercise instructions? This affects content tone and whether students need background knowledge.
    Options:
    - Guided: Step-by-step instructions with exact commands to copy-paste. Students follow a script. Best for Summit events where time is tight and students have varying skill levels.
    - Exploratory: Students get an objective ("configure Vault to issue SSH certificates") and figure out the approach themselves. Best for experienced audiences and longer sessions.
    - Mixed: Some modules are guided (early modules that teach concepts), others are exploratory (later modules that test understanding). The HashiCorp Summit lab does this: Module 1 is guided, Module 3 is more hands-on.

27. **Need solve/validate grading?**
    Automated scripts that check whether students completed each module correctly. Required for Summit labs. Solve scripts let proctors auto-complete a module if a student falls behind.
    Options:
    - No: Documentation only, no automated checking. Fine for demos or self-paced content.
    - Shell script grading: Traditional bash scripts (solve-control.sh / validation-control.sh). Scripts SSH into lab VMs and run checks. Simple but requires SSH access from the runner container.
    - Ansible grading (FTL): Ansible playbooks (solve.yml / validate.yml) using the Full Test Lifecycle framework. More structured, uses Ansible modules for checks.
    - API-driven: Ansible playbooks that use only ansible.builtin.uri to call REST APIs (AAP, Vault, TFE). No SSH access or Ansible collections needed. Runs from the Showroom runner container. This is the pattern proven in the most popular Summit lab (LB1390). Recommended for labs where students create API-accessible resources.
    - Both shell and Ansible: Shell scripts for OS-level checks, Ansible for service-level checks. Use when you need to verify both system state and API resources.

28. **Need a Remote Desktop (RDP)?**
    Browser-based remote desktop access to a VM in the lab. Used when students need a graphical interface (Windows administration, desktop applications).
    Options:
    - No: Terminal-only access is sufficient.
    - Yes, IronRDP for Windows access: Browser-based RDP client for Windows Server VMs. Students interact with Windows GUI (Server Manager, AD tools, etc.).
    - Yes, noVNC for Linux desktop: Browser-based VNC client for Linux desktop VMs. Students interact with a GNOME/KDE desktop (used for GUI tool demos).

29. **Cloud provider credentials for students?**
    Whether students need cloud provider access to provision resources outside the lab (e.g., create EC2 instances, S3 buckets, Azure VMs). Credentials are injected as environment variables at provisioning time.
    Options:
    - None needed: Lab is self-contained, no cloud provider access.
    - AWS credentials: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY injected. Used in the HashiCorp Summit lab for Terraform to provision EC2 instances. Credentials flow through the lab: env vars -> TFE workspace -> Vault secrets -> AAP credentials.
    - Azure credentials: Azure service principal credentials injected. For labs provisioning Azure resources.
    - AWS and Azure: Both cloud providers available. For multi-cloud automation labs.
    - GCP credentials: Google Cloud service account credentials. For labs using GCP resources.

### Phase 5: Operational Details

30. **Need AAP post-install configuration?**
    After AAP boots, should the lab automatically configure credentials, projects, inventories, job templates, and workflows? Or should students do this manually as part of the exercises?
    Options:
    - No (students configure manually): Students create AAP resources as part of the lab exercises. The lab starts with a blank AAP controller. Choose this when AAP configuration IS the learning objective.
    - Yes, full automation: Generate setup-aap-configure.sh that configures everything automatically. Students see a fully-configured AAP when they start. Choose this when students should focus on USING the automation, not building it. Generates OAuth token, credentials, projects, inventories, templates, and workflows.
    - Yes, partial: Auto-configure credentials and projects only. Students create job templates and workflows themselves. A middle ground that saves time on tedious setup while still teaching template creation.

31. **Lab duration?**
    How long is a single session? This affects how many modules you can cover and how deep each exercise goes.
    Options:
    - 45 minutes: Tight session, 2-3 guided modules max. Standard for Summit hands-on labs. Every minute counts; pre-configure as much as possible.
    - 60 minutes: Slightly more breathing room. Good for roadshows and regional events.
    - 90 minutes: Can cover 4-5 modules with some exploratory exercises. Good for workshops with experienced audiences.
    - 2+ hours: Full workshop or training session. Can include exploratory modules and deeper exercises. Default for internal training.
    - Self-paced: No time limit. Lab stays up for the configured lifespan. Students work at their own speed. Default for RHDP catalog items.

32. **Lab lifespan (how long should provisioned instances stay up)?**
    How long do the VMs and containers stay running before RHDP shuts them down? Set this longer than the duration to give students buffer time.
    Options:
    - 45 minutes: Minimum for Summit event sessions. VMs shut down immediately after the session slot.
    - 1 hour: Standard for event labs with some buffer.
    - 2 hours: Good for labs where students might want to explore after the guided portion.
    - 4 hours: Half-day labs or labs where students may take breaks.
    - 8 hours: Full-day training sessions. Also used for labs that take a long time to provision (avoids frequent re-provisioning).

33. **Multi-user support?**
    Whether each student gets their own dedicated infrastructure or shares a cluster with other students.
    Options:
    - Single user per instance: Each student gets their own AAP controller, VMs, and services. Complete isolation. This is the default for zero-touch labs and is recommended for most use cases.
    - Multiple users sharing one cluster: Multiple students share a single OCP cluster with namespace isolation. Used for OCP labs where a full cluster per student would be too expensive. Requires RBAC and namespace partitioning.

34. **LiteMaaS integration?**
    LiteMaaS provides on-demand GPU instances for AI/ML workloads. Required if the lab needs GPU-accelerated inference (e.g., RHEL AI with Granite model).
    Options:
    - No: Lab doesn't need GPU resources.
    - Yes: Enable LiteMaaS GPU allocation. Requires LiteMaaS API keys configured in the AgnosticV includes. The RHDP team provisions GPU instances on-demand during lab startup.

35. **Provisioning health webhook?**
    Send a notification when lab provisioning completes (or fails). Lets lab leads monitor deployment health at scale during events.
    Options:
    - No: No notifications. Fine for development and testing.
    - Slack channel: POST results to a Slack incoming webhook URL. You will be asked for the webhook URL. Used by TMM team to monitor Summit lab health in real-time.
    - Mattermost: POST results to a self-hosted Mattermost webhook. Same format as Slack.
    - Custom endpoint: POST a JSON report to any HTTP endpoint. Use for custom dashboards, PagerDuty, or integration with monitoring systems.

## Smart Defaults

Not every question needs to be asked. Use these rules to skip or auto-answer:

- If product is **RHEL** (not Ansible): skip AAP version, EDA, ChatOps, AI/LLM, AAP post-install
- If lab type is **showroom-only**: skip all infrastructure questions (Phase 2 and 3)
- If lab type is **agnosticv**: skip infrastructure details (they come from the referenced repo)
- If target is **internal training**: default to 2-hour duration, 4-hour lifespan
- If target is **Summit**: default to 45-min duration, 45-min lifespan
- If **no EDA**: skip Kafka and observability questions
- If **no AAP**: skip AAP version and AAP post-install questions
- If infrastructure is **docs-only**: skip all service questions
- If user mentions **HashiCorp, Vault, or Terraform**: auto-select Q20, load `zt-hashi-aap.md` reference
- If user mentions **zero trust, OPA, SPIFFE, or security policy**: auto-select Q22, load `zt-zero-trust-aap.md` reference
- If user selects **Vault + EDA + OPA**: suggest central node pattern (Q22 implies multi-service VM)

## After Interview

1. **Load references**: Check answers against `foundry/references/INDEX.md` tags.
   Load matching reference files for architecture guidance. Tell the user which
   references matched (e.g., "This looks similar to the HashiCorp Summit lab pattern").
2. Summarize the selections back to the user in a clear table
3. Ask for confirmation before scaffolding
4. Select the closest blueprint and customize it
5. Generate the complete repo structure
6. If AAP post-install selected (Q30): generate `setup-aap-configure.sh` from template
7. If EDA selected (Q13): generate rulebook from `eda/rulebook.yml.j2` and EDA setup script
8. If central node pattern detected: generate `setup-central-configure.sh` from template
9. Show what was created and what to do next

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

After selecting a blueprint, layer additional services from Phase 3 answers:
- Q20 (HashiCorp): Add Vault VM and/or TFE VM from service definitions
- Q21 (IDE): Add VSCode VM from service definitions
- Q22 (OPA/SPIRE): Add OPA container, optionally SPIRE container
- Q23 (NetBox): Add NetBox container
- Q17 (IdM as VM): Promote FreeIPA from container to VM, or use central node pattern

If 4+ services are co-dependent (e.g., IdM + Keycloak + OPA + Splunk), suggest the
central node pattern instead of individual containers.

## Reference Loading

After interview, match user selections to `foundry/references/INDEX.md` tags.
Load relevant reference files and use them to:
- Inform infrastructure sizing (e.g., central node needs 32GB if hosting 10+ services)
- Suggest setup orchestration patterns (phased vs parallel)
- Provide proven readiness check patterns for each service
- Suggest credential management approaches (Vault AppRole, OAuth tokens)
- Recommend module progression strategies (teardown/rebuild vs additive)

## Scaffolding

After interview and confirmation, create the repo structure as documented in the original skill definition. The key additions from the interview:

1. **config/instances.yaml**: Generated from blueprint + answers to Phase 2/3 questions
2. **config/firewall.yaml**: Ports derived from selected services
3. **config/networks.yaml**: Flat list of networks (always includes default)
4. **config/secrets.yaml**: MUST be copied verbatim from
   `templates/zero-touch/config/secrets.yaml` in the foundry plugin.
   This is a vault-encrypted file shared by all Ansible BU labs.
   Do NOT generate an empty placeholder. Do NOT create your own.
   Read the template file and write its exact contents to the lab repo.
5. **ui-config.yml**: Tabs for each service with a web UI, external: false
6. **site.yml / default-site.yml**: Antora site config with nookbag theme
7. **setup-automation/ansible.cfg**: host_key_checking = False (required for SSH)
8. **setup-automation/requirements.yml**: Collections to install (ansible.controller, ansible.platform)
9. **setup-automation/main.yml**: Bastion host pattern, add_host, all:!localhost
10. **setup-automation/setup-control.sh**: Phase 1 bootstrap: ansible.cfg with AH token, install collections from requirements.yml, clone automation repo. ALWAYS generated for Ansible labs.
11. **setup-automation/setup-control-configure.sh**: Phase 2: wait for AAP, generate OAuth token, run playbooks with ansible.controller modules to create credentials/inventory/project/templates. ALWAYS generated when AAP post-install is selected.
12. **setup-automation/setup-central-configure.sh**: Generated if central node pattern selected
13. **setup-automation/setup-eda-configure.sh**: Generated if Q13 = yes (EDA)
14. **eda/rulebook.yml**: Generated from template if Q13 = yes
15. **.foundry.yml**: Records all interview answers for future reference
16. **utilities/health-check.sh**: Generated if webhook URL provided (Phase 5, Q35)

## Config File Format Rules

When generating config files, use EXACTLY these formats. The RHDP runner
is strict about YAML structure and will fail with cryptic errors otherwise.

## Canonical networks.yaml and firewall.yaml

Copy these exactly. Do NOT modify the structure.

**config/networks.yaml** MUST be a flat YAML list at root level.
This is the most common scaffolding error. The RHDP runner passes
this file directly to a Jinja2 loop and it WILL fail if wrapped
in any key.

CORRECT (the ONLY valid format):
```yaml
---
- name: default
```

WRONG (causes "Invalid data passed to loop" error):
```yaml
---
networks:
  - name: default
```

After generating networks.yaml, ALWAYS verify the first non-comment
line after `---` starts with `- name:`, not `networks:`.

**config/firewall.yaml** must use flat indentation:
```yaml
---
ingress:
- ports:
  - protocol: TCP
    port: 443
```
Do NOT indent `- ports:` under `ingress:`.

**config/instances.yaml** rules are documented in the instances.yaml.j2 template header.

**config/secrets.yaml** is a constant vault-encrypted file shared across
all Ansible BU labs. Copy it from `templates/zero-touch/config/secrets.yaml`.
It contains: username, password, reg_username, reg_password, ssh_key,
ahtoken, vaultlic, tmm_activation, tmm_orgid. Lab developers can use
whichever vars they need. The vault password is provided by the RHDP
runner via VAULT_PASSWORD env var.

**setup-automation/requirements.yml** lists Ansible collections to install
on the controller VM before running setup playbooks. The setup script
should configure `~/.ansible.cfg` with Automation Hub auth (using ahtoken
from secrets.yaml) and then install collections from this file.

The pattern from Nuno's working labs:
```bash
# Configure Automation Hub auth
tee ~/.ansible.cfg > /dev/null <<EOF
[defaults]
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
EOF

# Install collections
ansible-galaxy collection install -r requirements.yml
```

With collections installed, the setup playbook can use `ansible.controller`
and `ansible.platform` modules directly instead of curl/API calls.

**ALL Ansible labs use a two-phase setup pattern** (from Nuno's production labs).
This is NOT specific to zero-trust. Every lab that has an AAP controller
MUST follow this pattern:

**Phase 1: `setup-control.sh` (bootstrap on controller VM)**
- Runs on the controller VM via SSH from the showroom setup container
- Configures `~/.ansible.cfg` with Automation Hub token from secrets.yaml
- Installs collections from `requirements.yml` via `ansible-galaxy`
- Fallback: symlinks `awx.awx` as `ansible.controller` if Hub unavailable
- Uses `set -euo pipefail` (safe here, no curl wait loop)
- Clones the lab automation repo to `/tmp/`

**Phase 2: `setup-control-configure.sh` (configure AAP)**
- Also runs on the controller VM
- Waits for AAP readiness via curl to `https://localhost/api/controller/v2/ping/`
  (port 443, NOT 8443)
- Generates OAuth token via POST to `/api/controller/v2/tokens/`
  (needed because awx.awx has broken token generation on AAP 2.6 Gateway)
- Runs Ansible playbooks using `ansible.controller` modules with token
  passed as extra var (`-e controller_oauth_token=$TOKEN`)
- Do NOT use `set -euo pipefail` (the curl wait loop must survive failures)

The setup playbooks use `ansible.controller` modules (credential, inventory,
project, job_template, workflow_job_template, etc.) because they run on the
controller VM where the collections were installed in Phase 1.

**main.yml orchestration:**
- Phase 1 and 2 run sequentially on the controller VM
- main.yml calls both scripts via `ansible.builtin.shell`
- Phase 2 is a separate script so the showroom pod can retry just the
  configure phase if AAP isn't ready yet on the first attempt

## Containers (Gitea, Splunk, etc.)

Containers work on both the Developer Experience CI and AgnosticV production.
Nuno confirms: "the gitea container works, I haven't had issues with it."

When generating a lab with containers:
- ALWAYS include the full container definition with `services:` and `routes:`
- Gitea needs `memory: 4Gi`, `volumeMounts`, `volumes`, and `commands`
- Gitea `commands` should create the admin user AND create an org for repos
- Use Nuno's proven Gitea definition from `foundry/references/zt-zero-trust-aap.md`

## Cross-Layer Consistency

When generating a lab, ensure all three layers are aligned:

1. **instances.yaml** defines which hosts exist
2. **Content pages** reference only hosts that exist in instances.yaml
3. **Validation scripts** check only for resources that content instructs students to create
4. **Solve scripts** create exactly what content describes
5. **ui-config.yml** tabs match services defined in instances.yaml

When infrastructure changes (e.g., removing a VM), update ALL layers:
- Remove host references from content pages
- Remove host checks from validation scripts
- Remove host creation from solve scripts
- Update ui-config.yml if a tab was associated with the removed host

If AAP post-install is "No" (students configure manually), content must
instruct students to create credentials, inventories, and templates.
Do NOT reference "pre-configured" resources when setup scripts don't create them.

## Canonical secrets.yaml

config/secrets.yaml is a vault-encrypted file that MUST be copied from
the foundry plugin's template directory. DO NOT generate it. DO NOT
create an empty placeholder. DO NOT write `secrets: []`.

To create it: Read the file `templates/zero-touch/config/secrets.yaml`
from the foundry plugin repo (relative to the plugin root) and write
its EXACT contents to `config/secrets.yaml` in the new lab. The file
is located two levels up from this skill's directory, at
`../../templates/zero-touch/config/secrets.yaml`.

This file contains vault-encrypted variables including `ahtoken`
(Automation Hub token), `ssh_key`, `reg_username`, `reg_password`,
`vaultlic`, and `tmm_activation`. The vault password is provided by
the RHDP runner via the VAULT_PASSWORD environment variable.

## Canonical instances.yaml Example

ALWAYS use this exact format when generating instances.yaml. Copy this
structure and modify names/counts. Do NOT invent your own YAML structure.

```yaml
---
virtualmachines:
  - name: control
    image: aap-2.6-6-ceh-20260325
    memory: 32G
    cores: 4
    image_size: 50Gi
    tags:
      - key: AnsibleGroup
        value: isolated
    networks:
      - default
    services:
      - name: control-https
        ports:
          - port: 443
            protocol: TCP
            targetPort: 443
            name: control-https
    routes:
      - name: control-https
        host: control
        service: control-https
        targetPort: 443
        tls: true
        tls_termination: reencrypt
        tls_destinationCACertificate: |
          -----BEGIN CERTIFICATE-----
          <AAP CA cert from blueprint>
          -----END CERTIFICATE-----
    userdata: |-
      #cloud-config
      user: rhel
      password: ansible123!
      chpasswd: { expire: False }
      runcmd:
        - echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/50-cloud-init.conf
        - systemctl reload sshd

  - name: rhel-1
    image: rhel-9.5
    memory: 4G
    cores: 2
    image_size: 30Gi
    tags:
      - key: AnsibleGroup
        value: isolated
    networks:
      - default
    userdata: |-
      #cloud-config
      user: rhel
      password: ansible123!
      chpasswd: { expire: False }
      runcmd:
        - echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/50-cloud-init.conf
        - systemctl reload sshd
```

Key patterns that MUST be followed exactly:
- `services.ports` is a LIST of objects with port/protocol/targetPort/name
- NOT `services.port` (singular, flat)
- `memory` uses `G` for VMs (not `Gi`)
- `tags` uses `key`/`value` pairs (not flat dict)
- `networks` is a list with `- default`
- `userdata` uses `|-` with `runcmd` (not `ssh_pwauth`)
- AAP route has `tls_destinationCACertificate`

## Canonical setup-control.sh (Phase 1: Bootstrap)

ALWAYS use this exact structure. Modify collection list as needed.

```bash
#!/bin/bash
set -euo pipefail

echo "Starting Control node setup (bootstrap phase)..."
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

retry() {
    local max_attempts=3 delay=5 desc="$1"; shift
    for ((i = 1; i <= max_attempts; i++)); do
        echo "Attempt $i/$max_attempts: $desc"
        if "$@"; then return 0; fi
        [ $i -lt $max_attempts ] && sleep $delay
    done
    echo "FATAL: Failed after $max_attempts attempts: $desc"; exit 1
}

run_if_needed() {
    local desc="$1"; shift
    local check=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do check+=("$1"); shift; done
    shift
    if "${check[@]}" &>/dev/null; then echo "SKIP: $desc"
    else retry "$desc" "$@"; fi
}

for var in AH_TOKEN; do
    [ -z "${!var:-}" ] && { echo "ERROR: $var not set"; exit 1; }
done

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
EOF

run_if_needed "Install base packages" rpm -q git -- dnf install -y dnf-utils git

tee /tmp/requirements.yml > /dev/null <<EOF
---
collections:
  - name: ansible.controller
  - name: ansible.posix
  - name: community.general
EOF

run_if_needed "Install Ansible collections" \
    bash -c 'ansible-galaxy collection list | grep -q "ansible.controller"' \
    -- ansible-galaxy collection install -r /tmp/requirements.yml

if ! ansible-galaxy collection list 2>/dev/null | grep -q "ansible.controller"; then
    echo "INFO: ansible.controller not found; symlinking awx.awx"
    mkdir -p ~/.ansible/collections/ansible_collections/ansible
    ln -sfn ~/.ansible/collections/ansible_collections/awx/awx \
            ~/.ansible/collections/ansible_collections/ansible/controller
fi

echo "Control bootstrap phase complete."
```

## Canonical setup-control-configure.sh (Phase 2: Configure AAP)

ALWAYS use this exact structure. Modify the inline playbook tasks as needed.
Do NOT use `set -euo pipefail`. Do NOT use `controller_validate_certs` as
a play var. ALWAYS use `module_defaults` with `validate_certs: false`.
ALWAYS use `https://localhost` (port 443, NOT 8443).
Credential username/password MUST match the VM userdata user/password.

```bash
#!/bin/bash
# No set -euo pipefail: curl wait loop must survive failures

echo "Starting Control node setup (configure phase)..."
export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INVENTORY_UNPARSED_WARNING=False

AAP_HOST="https://localhost"
AAP_USER="admin"
AAP_PASS="ansible123!"

echo "Waiting for AAP controller..."
for i in $(seq 1 60); do
    CODE=$(curl -sk -o /dev/null -w "%{http_code}" \
        "${AAP_HOST}/api/controller/v2/ping/" \
        -u "${AAP_USER}:${AAP_PASS}" 2>/dev/null || echo "000")
    if [ "$CODE" = "200" ]; then
        echo "  AAP ready (attempt $i)"; break
    fi
    [ "$i" = "60" ] && { echo "FATAL: AAP not ready"; exit 1; }
    echo "  waiting... (attempt $i, HTTP $CODE)"; sleep 10
done

echo "Generating AAP OAuth token..."
CONTROLLER_OAUTH_TOKEN=$(curl -sk -X POST \
    "${AAP_HOST}/api/controller/v2/tokens/" \
    -H "Content-Type: application/json" \
    -u "${AAP_USER}:${AAP_PASS}" \
    -d '{"description":"setup","application":null,"scope":"write"}' | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
[ -z "${CONTROLLER_OAUTH_TOKEN}" ] && { echo "FATAL: No token"; exit 1; }
echo "  Token OK"

export CONTROLLER_HOST="${AAP_HOST}"
export CONTROLLER_OAUTH_TOKEN
export CONTROLLER_VERIFY_SSL=false

cat > /tmp/configure-aap.yml << 'PLAYBOOK'
---
- name: Configure AAP
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

    - name: Create project
      ansible.controller.project:
        name: "Lab Project"
        organization: "Default"
        scm_type: git
        scm_url: "https://github.com/OWNER/REPO.git"
        scm_branch: main
        state: present
        wait: true
        timeout: 120

    - name: Create inventory
      ansible.controller.inventory:
        name: "Lab Inventory"
        organization: "Default"
        state: present

    - name: Add host
      ansible.controller.host:
        name: node1
        inventory: "Lab Inventory"
        state: present

    - name: Create job template
      ansible.controller.job_template:
        name: "My Job Template"
        organization: "Default"
        project: "Lab Project"
        playbook: playbooks/main.yml
        inventory: "Lab Inventory"
        credential: "Lab Machine Credential"
        job_type: run
        state: present
PLAYBOOK

ansible-playbook /tmp/configure-aap.yml

echo "Configure phase complete."
```

## Canonical main.yml (Setup Orchestrator)

ALWAYS use this exact structure. Loads secrets.yaml for AH token,
runs both phases sequentially on the controller VM.

```yaml
---
- name: Create inventory
  hosts: localhost
  gather_facts: false
  vars_files:
    - ../config/secrets.yaml
  tasks:
    - name: Add control host
      ansible.builtin.add_host:
        name: control
        ansible_ssh_host: "{{ lookup('env', 'BASTION_HOST') }}"
        ansible_ssh_port: "{{ lookup('env', 'BASTION_PORT') }}"
        ansible_ssh_user: "{{ lookup('env', 'BASTION_USER') }}"
        ansible_ssh_pass: "{{ lookup('env', 'BASTION_PASSWORD') }}"
        ansible_become_password: "{{ lookup('env', 'BASTION_PASSWORD') }}"
        ah_token: "{{ ahtoken }}"

- name: Setup control node
  hosts: control
  gather_facts: false
  tasks:
    - name: Wait for SSH
      ansible.builtin.wait_for_connection:
        timeout: 300
    - name: Create scripts directory
      ansible.builtin.file:
        path: /tmp/setup-scripts
        state: directory
        mode: "0755"
    - name: Copy bootstrap script
      ansible.builtin.copy:
        src: ./setup-control.sh
        dest: /tmp/setup-scripts/setup-control.sh
        mode: "0755"
    - name: Copy configure script
      ansible.builtin.copy:
        src: ./setup-control-configure.sh
        dest: /tmp/setup-scripts/setup-control-configure.sh
        mode: "0755"
    - name: "Phase 1: Bootstrap"
      ansible.builtin.shell: >-
        /tmp/setup-scripts/setup-control.sh
        > /tmp/setup-scripts/setup-control.log 2>&1
      become: true
      environment:
        AH_TOKEN: "{{ ah_token }}"
    - name: "Phase 2: Configure AAP"
      ansible.builtin.shell: >-
        /tmp/setup-scripts/setup-control-configure.sh
        > /tmp/setup-scripts/setup-control-configure.log 2>&1
      become: true
```

## Post-Scaffolding Validation

After generating all files, ALWAYS run these checks before reporting
success. These catch the most common errors that cause provisioning
failures:

1. **networks.yaml**: Read the file back. First non-comment line after
   `---` MUST start with `- name:`. If it starts with `networks:`,
   fix it immediately.

2. **firewall.yaml**: First entry under `ingress:` must be `- ports:`
   at the same indentation level, not indented further.

3. **instances.yaml**: Read the file back and verify ALL of these:
   - AAP image is EXACTLY `aap-2.6-6-ceh-20260325` (not `base-zero-aap-*`)
   - RHEL image is EXACTLY `rhel-9.5` (not `rhel93`)
   - AAP controller memory is `32G`
   - VM memory uses `G` not `Gi`
   - Every VM has `networks:` with `- default`
   - Every VM has `tags:` as list of `{key: X, value: Y}` objects,
     NOT flat dicts like `{AnsibleGroup: control}`.
     CORRECT: `- key: AnsibleGroup\n  value: isolated`
     WRONG: `- AnsibleGroup: control`
   - Every VM has `userdata: |-` with runcmd for SSH
   - AAP route has `tls_destinationCACertificate`
   - Container environment is flat dict not list
   - Container service ports have `name` field

4. **ansible.cfg**: Must exist in setup-automation/ with
   `host_key_checking = False`.

5. **Content consistency**: Every hostname in content pages must exist
   in instances.yaml.

6. **Credential consistency**: The machine credential username/password
   in setup-control-configure.sh MUST match the user/password in the
   VM userdata in instances.yaml. If userdata creates user `rhel` with
   password `ansible123!`, the credential must use the same values.

## Important Notes

- NEVER skip the interview. The exhaustive question set is what makes this tool valuable.
- For each question, show the recommended/default option first.
- Group questions logically, don't ask all 30 at once. Use 5 phases.
- If the user says "just like the EDA lab" or references an existing lab, read that lab's .foundry.yml or config/ to pre-populate answers.
- Save all answers to .foundry.yml so the lab can be rebuilt or modified later.
