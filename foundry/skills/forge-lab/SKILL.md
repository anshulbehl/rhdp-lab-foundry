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

1. **instances.yaml**: Generated from blueprint + answers to Phase 2/3 questions
2. **firewall.yaml**: Ports derived from selected services
3. **ui-config.yml**: Tabs for each service with a web UI
4. **setup-automation/setup-control.sh**: AAP version-specific setup using `ansible.controller` modules
5. **setup-automation/setup-aap-configure.sh**: Generated from template if Q30 = yes (AAP post-install)
6. **setup-automation/setup-central-configure.sh**: Generated if central node pattern selected
7. **setup-automation/setup-eda-configure.sh**: Generated if Q13 = yes (EDA)
8. **eda/rulebook.yml**: Generated from template if Q13 = yes
9. **.foundry.yml**: Records all interview answers for future reference
10. **utilities/health-check.sh**: Generated if webhook URL provided (Phase 5, Q35)

## Container Route Limitation

The Developer Experience CI (used for testing labs before AgnosticV onboarding)
does NOT create external routes for containers. It only creates routes for VMs.
Container routes are created automatically when the lab is onboarded to AgnosticV.

When generating a lab:
- Container services (Gitea, Splunk, Mattermost) will NOT have external routes
  when testing via the Developer Experience CI
- For testing: either remove container tabs from ui-config.yml, or tell the user
  to manually create the route via `oc create route` on the cluster
- For production: container routes work automatically through AgnosticV
- VM services (AAP controller, Vault, etc.) always get routes on both CI types

When generating ui-config.yml:
- Include container tabs with a comment noting they require AgnosticV deployment
- For Developer Experience CI testing, suggest using Terminal tab to access
  container services via curl (e.g., `curl http://gitea:3000`)

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

## Important Notes

- NEVER skip the interview. The exhaustive question set is what makes this tool valuable.
- For each question, show the recommended/default option first.
- Group questions logically, don't ask all 30 at once. Use 5 phases.
- If the user says "just like the EDA lab" or references an existing lab, read that lab's .foundry.yml or config/ to pre-populate answers.
- Save all answers to .foundry.yml so the lab can be rebuilt or modified later.
