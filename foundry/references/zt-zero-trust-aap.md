# Reference: Zero Trust with Ansible Automation Platform

Source: `rhpds/zt-ans-bu-zta-aap` (Summit 2026, LB2864)
Author: Nuno Martins

## Architecture Overview

NIST SP 800-207 Zero Trust Architecture using AAP as Policy Enforcement Point (PEP),
Open Policy Agent as Policy Decision Point (PDP), and multiple Policy Information Points
(IdM, NetBox, Vault, Splunk).

## Infrastructure Topology

4 VMs, 1 container (Gitea), 2 networks (default + secondary).

| VM | Image | Memory | Cores | Disk | Role |
|:---|:------|:-------|:------|:-----|:-----|
| control | aap-2.6-2-ceh-20251103 | 64GB | 8 | 80Gi | AAP controller |
| central | zta-central-img-v1.3 | 32GB | 8 | 70Gi | Multi-service node (22 services) |
| vault | vault-rhel-image-1 | 16GB | 4 | 40Gi | HashiCorp Vault Enterprise |
| netbox | rhel-9.5 | 16GB | 4 | 30Gi | NetBox CMDB (Docker Compose) |

Total: 128GB RAM, 24 cores, 220Gi disk.

### Central Node Pattern (Key Pattern)

The central VM hosts 22 services on a single node. This is the "multi-service VM" pattern
where services share a private network and local IPC. Services run via podman containers
and systemd units on the same host.

Services on central:
- **Identity**: IdM/FreeIPA (ports 80, 443, 389, 636, 88, 464)
- **Auth**: Keycloak (ports 8180, 8543)
- **Policy**: OPA (port 8181)
- **Logging**: Splunk (ports 8000, 8088, 8089, 9997)
- **Network**: 3x Arista cEOS switches (ports 6031-6033)
- **App stack**: PostgreSQL (5432), app container (8081), db container (SSH 2022), app container (SSH 2023)
- **SCM**: Gitea (port 3000)
- **Dashboard**: ZTA topology dashboard (port 5050)

Why one VM instead of many: services need to share DNS (IdM is the DNS server for the
lab domain), local podman networking, and IPA client enrollment. Splitting them would
require complex cross-VM networking.

### Route Patterns

Two TLS termination strategies used:
- **Edge**: OPA, Splunk, Gitea, Dashboard, App (TLS terminates at OpenShift router)
- **Reencrypt**: IdM HTTPS, Keycloak (backend has its own cert, router re-encrypts)

## Setup Orchestration

5-phase bootstrap with cross-host dependencies and readiness gates.

### Phase Timing
| Phase | Delay | What |
|:------|:------|:-----|
| 1 | 0s | Dynamic inventory with host vars (IPs, interfaces, DNS) |
| 2 | 90s | Common bootstrap on all hosts (RHSM, SELinux, firewalld, /etc/hosts, DNS) |
| 3 | 300s | Host-specific bootstrap (setup-vault.sh, setup-netbox.sh, setup-central.sh, setup-control.sh) |
| 4 | 200s | Central service-dependent config (waits for Vault unseal + NetBox API) |
| 5 | 180s | AAP configuration (waits for Vault KV engine mount) |

### Readiness Gate Patterns

```yaml
# Wait for Vault unsealing (command-based check)
retries: 30, delay: 10
check: vault status -address=http://127.0.0.1:8200, rc == 0

# Wait for NetBox API (HTTP check)
retries: 30, delay: 10
check: GET http://127.0.0.1:8000, status == 200

# Wait for Vault KV engine (HTTP check with multiple acceptable codes)
retries: 12, delay: 10
check: GET http://192.168.1.12:8200/v1/sys/internal/ui/mounts/secret, status in [200, 403]

# Wait for AAP controller (HTTP check)
retries: 60, delay: 10
check: GET https://control.zta.lab/api/controller/v2/ping/, status == 200
```

### Environment Variables Passed to Setup Scripts
SATELLITE_URL, SATELLITE_ORG, SATELLITE_ACTIVATIONKEY, GUID, DOMAIN,
REG_KEY, REG_PASS, SSH_KEY, VAULT_LIC, AH_TOKEN, TMM_ID, TMM_ORG

## AAP Post-Install Configuration

OAuth token generated via POST /api/controller/v2/tokens/ with admin credentials.
Configuration runs as Ansible playbooks with token passed as extra var.

Order of operations:
1. Credentials (Vault machine, Arista, NetBox, SSH CA)
2. Dashboard deployment
3. Static inventory
4. Project + Execution Environment (--tags ee,project)
5. Inventory refresh (after project sync)
6. NetBox CMDB inventory source
7. Section 1 job templates (--tags section1)
8. EDA project + decision environment + event stream (--tags eda)
9. Splunk EDA webhook integration

Tag-driven playbook filtering allows phased configuration: each module section
gets its own tag, so runtime automation can remove previous section templates
and create next section's templates.

## OPA Integration (Key Pattern)

Two levels of OPA policy enforcement:
1. **AAP Platform Level**: Settings -> Policy -> OPA hostname. AAP queries OPA
   before enqueuing any job. Playbook never executes if policy denies.
   Policy path: `aap/gateway/decision`
2. **Playbook Level**: Playbook tasks call OPA via ansible.builtin.uri for
   fine-grained decisions (e.g., VLAN range checks, user group checks).

Policy mapping:
- Patch templates require Infrastructure or Security team membership
- VLAN/Network templates require Infrastructure team
- Deploy/Credential templates require Applications or DevOps team

## SPIFFE/SPIRE Pattern (Key Pattern)

Two independent policy rings evaluate both the human (outer) and the workload (inner).

- SPIRE Server runs on central, SPIRE Agent on control
- Trust domain: zta.lab (matches IdM domain)
- SPIFFE ID format: spiffe://zta.lab/workload/network-automation
- SVIDs are X.509 certificates with SPIFFE ID as SAN
- Playbooks fetch SVID, parse SPIFFE ID, fail closed if missing or untrusted
- OPA checks both user identity AND workload SPIFFE ID

## EDA Incident Response Chain (Key Pattern)

Splunk detects SSH brute force -> triggers EDA webhook -> EDA revokes Vault
DB credentials -> app goes unhealthy.

Components:
- Splunk saved search: "ZTA: SSH Brute Force Detected" (count >= 5 auth failures per src_ip)
- Event Stream: Token-based, credential: ZTA EDA Event Stream
- Splunk Add-on: Event-Driven Ansible Add-on, webhook to AAP EDA endpoint
- Rulebook: splunk-credential-revoke.yml (source: ansible.eda.pg_listener or webhook)
- Decision Environment: Default Decision Environment
- Action: Run job template to revoke Vault DB lease, remove env file, stop app

## Module Progression Pattern

Runtime automation scripts tear down previous section and build next:
- module-02/setup-central.sh: Removes Section 1 templates, creates Section 2
- module-03/setup-central.sh: Creates Section 3, moves users between IdM groups
- module-04/setup-central.sh: Removes Section 3, creates Section 4
- module-05/setup-central.sh: Removes Section 4, creates Section 5

Each transition generates a fresh OAuth token and uses tag-driven playbooks.

## Content Structure

7 modules (5 active, 2 WIP):
1. Verify ZTA Components and AAP Integration (6 exercises)
2. Deploy application with short-lived credentials (4 exercises + 2 hands-on)
3. AAP Policy as Code: platform-gated patching (2 exercises)
4. SPIFFE-verified network VLAN management (3 exercises + hands-on)
5. Automated incident response with Splunk and EDA (7 exercises)
6. SSH lockdown and break-glass recovery (WIP)
7. Wazuh SIEM (optional, WIP)

Hands-on exercises include intentional bugs (broken playbooks) and FILL_IN
placeholder tasks for students to complete.

## Service Credentials

| Service | Username | Password |
|:--------|:---------|:---------|
| AAP | admin | ansible123! |
| IdM (FreeIPA) | admin | ansible123! |
| Vault | admin | ansible123! |
| NetBox | admin | netbox |
| Splunk | admin | ansible123! |
| Gitea | gitea | ansible123! |
| Keycloak | admin | ansible123! |

IdM scenario accounts: ztauser, netadmin, appdev, neteng (all ansible123!)
