# Reference: AAP + HashiCorp Terraform and Vault

Source: `rhpds/zt-ans-bu-hashi-aap` (Summit 2026, LB1390)
Author: Hicham Mourad
Note: Most popular lab at Summit 2026.

## Architecture Overview

Multi-product enterprise automation: AAP orchestrates Terraform Enterprise for
infrastructure provisioning and Vault Enterprise for secret management. Students
get a full VSCode development environment to write and test infrastructure code.

## Infrastructure Topology

4 VMs, 0 standalone containers, 2 networks (default + secondary).

| VM | Image | Memory | Cores | Disk | Role |
|:---|:------|:-------|:------|:-----|:-----|
| control | aap-2.6-2-ceh-20251103 | 32GB | 4 | 50Gi | AAP controller |
| vscode | devtools-ansible | 8GB | 2 | 20Gi | VSCode code-server IDE |
| terraform | tfe-rhel-image-1 | 16GB | 4 | 120Gi | Terraform Enterprise |
| vault | vault-rhel-image-1 | 16GB | 2 | 40Gi | HashiCorp Vault Enterprise |

Total: 72GB RAM, 12 cores, 230Gi disk.

### VSCode IDE VM Pattern (Key Pattern)

Dedicated development VM for students to write code, test locally, and interact
with cloud providers. Not a target for automation; it IS the workstation.

Setup includes:
- code-server listening on 0.0.0.0:8080 with auth=none
- AWS CLI v2 installed from official zip
- Terraform CLI installed via HashiCorp RPM repo
- ~/.aws/credentials auto-populated from lab env vars
- Default VPC created: `aws ec2 create-default-vpc`
- Random S3 bucket for Terraform state: `aap-tf-bucket-${UUID}`
- ansible-builder + podman for custom EE builds
- Systemd linger enabled for persistent podman containers
- 4096-bit RSA SSH key generated for student use

### Terraform Enterprise Pattern (Key Pattern)

TFE runs as a podman container on a dedicated VM with persistent storage.

Container configuration:
- Image: images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202501-1
- Login to registry with TFE license token
- TFE_OPERATIONAL_MODE: disk (no external database needed)
- TFE_HOSTNAME: tfe-https-${GUID}.${DOMAIN} (dynamic hostname)
- Custom TLS certificates: base64-decoded into /home/ec2-user/tfeinstallfiles/certs/
- Volumes: certs, logs, tmpfs for /run, data at /opt/terraform-enterprise
- PVC for terraform cache
- CAP_IPC_LOCK capability, seLinux spc_t type
- Managed via systemd quadlet (tfe.yaml in /etc/containers/systemd/)

### Route TLS Patterns

- **control**: Reencrypt (AAP has its own cert, embedded CA cert in route definition)
- **tfe-https**: Reencrypt (TFE has custom cert, embedded CA cert)
- **vault**: Edge (Vault UI served plain, TLS at router)
- **vscode**: Edge (code-server serves plain HTTP on 8080)

## Setup Orchestration

Single-phase: all 4 setup scripts run in parallel after inventory creation.

### Environment Variables Passed to Setup Scripts
SATELLITE_URL, SATELLITE_ORG, SATELLITE_ACTIVATIONKEY,
AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION,
GUID, DOMAIN, QUAY_USERNAME, QUAY_PASSWORD,
REG_KEY, REG_PASS, SSH_KEY, VAULT_LIC, TFE_LIC

### setup-control.sh Pattern (Inline Playbook)

Instead of calling external playbooks, this lab generates an inline Ansible playbook
at /tmp/setup.yml and runs it with ansible-playbook. The playbook uses
ansible.controller collection modules to configure AAP:

```
ansible.controller.credential (AWS, SSH Machine, Quay Registry)
ansible.controller.execution_environment (Terraform EE from Quay)
ansible.controller.project (Git repo with Terraform playbooks)
ansible.controller.job_template (delete Demo, create Install Nginx)
ansible.controller.inventory + host (Terraform Inventory)
```

This is simpler than the tag-driven external playbook approach used in the ZT lab.
Suitable when the AAP configuration is static and doesn't change between modules.

### setup-vault.sh Pattern

Identical to ZT lab: write license file, restart service, unseal with hardcoded key.
Unseal key: `1c6a637e70172e3c249f77b653fb64a820749864cad7f5aa7ab6d5aca5197ec5`

## AAP Post-Install Configuration (Key Pattern)

This lab configures AAP within the setup-control.sh script using an inline playbook.
The configuration creates:

1. **Custom credential type** (Terraform Enterprise):
   - Input fields: hostname, organization, workspace, token
   - Injector: extra_vars mapping each field

2. **Multiple credential types used**:
   - Amazon Web Services (access_key + secret_key)
   - Machine (SSH key for ec2-user)
   - Container Registry (Quay credentials)
   - HashiCorp Vault Secret Lookup (vault_url, vault_auth_method=approle, role_id, secret_id)
   - Custom TFE credential type

3. **Workflow job templates with node linking**:
   - WF-APPLY: APPLY job -> Inventory sync -> Install Nginx (success chain)
   - WF-DESTROY: DESTROY job -> Inventory sync (success chain)
   - WF-Launched by TFE: Inventory sync -> Install Nginx (prompt on launch for dynamic inventory)

## API-Driven Solve/Validate Pattern (Key Pattern)

The lb1390-validation branch demonstrates solve/validate using pure API calls
instead of SSH scripts. All operations use ansible.builtin.uri against the
AAP controller API, TFE API, and Vault API.

This works from the Showroom runner container which has no SSH access to lab VMs
and no Ansible collections installed. Only the uri module is available.

### Solve Pattern (module-01 example):
```yaml
# 1. Get TFE project ID
ansible.builtin.uri: GET {{ tfe_url }}/api/v2/organizations/{{ tfe_org }}/projects

# 2. Create TFE workspace
ansible.builtin.uri: POST {{ tfe_url }}/api/v2/organizations/{{ tfe_org }}/workspaces

# 3. Add AWS vars to workspace
ansible.builtin.uri: POST {{ tfe_url }}/api/v2/workspaces/{{ ws_id }}/vars

# 4. Create custom credential type in AAP
ansible.builtin.uri: POST {{ aap_url }}/api/controller/v2/credential_types/

# 5. Create credential in AAP
ansible.builtin.uri: POST {{ aap_url }}/api/controller/v2/credentials/

# 6. Create inventory source
ansible.builtin.uri: POST {{ aap_url }}/api/controller/v2/inventory_sources/

# 7. Create job templates
ansible.builtin.uri: POST {{ aap_url }}/api/controller/v2/job_templates/

# 8. Create workflow + nodes + links
ansible.builtin.uri: POST {{ aap_url }}/api/controller/v2/workflow_job_templates/
ansible.builtin.uri: POST .../workflow_job_template_nodes/
ansible.builtin.uri: POST .../success_nodes/
```

### Validate Pattern:
```yaml
# Check resource exists via API query
ansible.builtin.uri: GET {{ aap_url }}/api/controller/v2/credential_types/?name=Terraform%20Enterprise
# Assert count > 0
```

## AWS Credential Flow (Key Pattern)

Same AWS credentials flow through 4 systems:
1. **Environment vars** (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) injected at provisioning
2. **VSCode VM**: Written to ~/.aws/credentials for CLI and Terraform use
3. **TFE workspace**: Added as sensitive environment variables
4. **Vault**: Stored as KV secret at secret/aws_creds
5. **AAP**: Created as Amazon Web Services credential type

## Custom Execution Environment Pattern

Students learn to build EEs with HashiCorp collections:
- Base: ee-minimal-rhel9
- Collections: amazon.aws, cloud.terraform, hashicorp.terraform, hashicorp.vault,
  google.cloud, azure.azcollection
- Additional build steps: Download Terraform binary 1.14.1
- Build: `ansible-builder build -v 3 --tag hashicorp-ee`
- Push to Quay, add to AAP via Infrastructure -> Execution Environments

## Content Structure

4 modules:
1. AAP + Terraform Enterprise Integration (create workspace, credential type, workflows, launch apply/destroy)
2. Vault + AppRole + Secret Injection (KV engine, policies, AppRole auth, Vault lookup credential in AAP)
3. Terraform VCS Workflow (GitHub integration, TFE webhook triggers, end-to-end: commit -> TFE -> Vault -> AAP)
4. Execution Environment Creation (educational, hands-off: ansible-builder concepts)

## Service Credentials

| Service | Username | Password |
|:--------|:---------|:---------|
| AAP | admin | ansible123! |
| Vault | admin | ansible123! |
| TFE | (token-based) | (generated at setup) |
| VSCode | (no auth) | (auth=none) |

## What Made This Lab Popular

1. Real enterprise products (TFE, Vault Enterprise), not toy examples
2. Students get a full IDE to write and test code
3. End-to-end workflow: Git commit triggers infrastructure provisioning automatically
4. Multi-product orchestration that maps directly to real-world architecture
5. Each module builds on the previous, creating a complete pipeline by module 3
6. Clean API-driven validation that confirms students completed exercises correctly
