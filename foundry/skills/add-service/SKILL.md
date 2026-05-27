---
name: foundry:add-service
description: Add a VM, container, or route to an existing lab's infrastructure config. Updates instances.yaml, firewall.yaml, and ui-config.yml. Use when asked to "add a service", "add a VM", "add a container", "add nginx", "add Splunk", or "add a route to my lab".
context: main
model: claude-sonnet-4-6
---

# Add Service - Add Infrastructure to a Lab

Adds a virtual machine, container, or route to an existing lab's config/ directory.

## Pre-flight

1. Verify this is a zero-touch lab (config/instances.yaml must exist)
2. Read the current config/instances.yaml to understand existing infrastructure
3. Read ui-config.yml to understand existing tabs/routes

## Gather Information

Ask the user:
1. **What service?** (e.g., "Splunk", "Mattermost", "FreeIPA", "nginx", or a custom service)
2. **VM or container?** (VMs for heavy workloads, containers for lightweight services)
3. **What ports?** (e.g., 8000 for web UI, 8088 for API)
4. **Should it have a UI tab?** (yes = add to ui-config.yml)

For known services, use pre-built definitions:

| Service | Type | Image | Ports | Memory |
|:--------|:-----|:------|:------|:-------|
| Splunk | container | docker.io/splunk/splunk:latest | 8000, 8088, 8089 | 2GB |
| Mattermost | container | docker.io/mattermost/mattermost-team-edition | 8065 | 1GB |
| FreeIPA | container | quay.io/freeipa/freeipa-server:rocky-9 | 636, 389, 88, 464 | 2GB |
| Gitea | container | docker.io/gitea/gitea:1.16.8-rootless | 3000 | 512MB |
| Kafka | container | docker.io/apache/kafka:latest | 9092 | 1GB |
| nginx | container | docker.io/library/nginx:latest | 80, 443 | 256MB |
| PostgreSQL | container | docker.io/library/postgres:16 | 5432 | 512MB |
| RHEL node | vm | rhel-9.5 | 22 | 4GB, 2 cores |
| HashiCorp Vault | vm | vault-rhel-image-1 | 8200, 8201 | 16GB, 2 cores |
| Terraform Enterprise | vm | tfe-rhel-image-1 | 443, 8443 | 16GB, 4 cores |
| VSCode (code-server) | vm | devtools-ansible | 8080 | 8GB, 2 cores |
| Keycloak | container | registry.redhat.io/rhbk/keycloak-rhel9:24 | 8180, 8543 | 2GB |
| NetBox | container | docker.io/netboxcommunity/netbox:latest | 8000 | 2GB |
| OPA | container | docker.io/openpolicyagent/opa:latest | 8181 | 512MB |
| SPIRE Server | container | ghcr.io/spiffe/spire-server:latest | 8081 | 512MB |
| EDA Webhook | service | (built into AAP) | 5000 | N/A |

## Actions

1. **Add to instances.yaml**: Insert the VM or container definition following existing patterns
2. **Add to firewall.yaml**: Add ingress rules for the service's ports
3. **Add to ui-config.yml**: Add a tab entry if the service has a web UI
4. **Add setup stub**: Create a setup script stub in setup-automation/ if needed
5. **Update .foundry.yml**: Add the service to the services list

## Detailed Service Definitions

When adding a known service, use these full YAML definitions. Adapt ports, credentials,
and environment variables to the specific lab.

### HashiCorp Vault (VM)

Vault Enterprise requires a pre-baked image with Vault installed and a license file.
Setup script handles license injection and unseal. See `foundry/references/zt-zero-trust-aap.md`.

```yaml
# instances.yaml
virtualmachines:
  - name: vault
    image: vault-rhel-image-1
    memory: 16G
    cores: 2
    image_size: 40Gi
    tags:
      - key: AnsibleGroup
        value: isolated
    services:
      - name: vault-8200
        ports:
          - port: 8200
            protocol: TCP
            targetPort: 8200
            name: vault-8200
    routes:
      - name: vault
        host: vault
        service: vault-8200
        targetPort: 8200
        tls: true
        tls_termination: Edge
    userdata: |-
      #cloud-config
      user: rhel
      password: ansible123!
      chpasswd: { expire: False }
      runcmd:
        - echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/50-cloud-init.conf
        - systemctl reload sshd
```

Setup stub (`setup-vault.sh`): Write VAULT_LIC to /etc/vault.d/vault.hclic, restart vault service,
unseal with stored key. Idempotent (skip if already unsealed).

### Terraform Enterprise (VM)

TFE runs as a podman container on a dedicated VM. Requires TFE_LIC env var and registry login.
See `foundry/references/zt-hashi-aap.md`.

```yaml
# instances.yaml
virtualmachines:
  - name: terraform
    image: tfe-rhel-image-1
    memory: 16G
    cores: 4
    image_size: 120Gi
    tags:
      - key: AnsibleGroup
        value: isolated
    services:
      - name: tfe-https
        ports:
          - port: 443
            protocol: TCP
            targetPort: 443
            name: tfe-https
    routes:
      - name: tfe-https
        host: tfe-https
        service: tfe-https
        targetPort: 443
        tls: true
        tls_termination: reencrypt
    userdata: |-
      #cloud-config
      user: rhel
      password: ansible123!
      chpasswd: { expire: False }
      runcmd:
        - echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/50-cloud-init.conf
        - systemctl reload sshd
```

Setup stub (`setup-terraform.sh`): Login to images.releases.hashicorp.com, generate
systemd quadlet (tfe.yaml), configure TFE_HOSTNAME with GUID/DOMAIN, decode TLS certs,
start container.

### VSCode / code-server (VM)

Student development environment with pre-installed tooling. No authentication on the
code-server (auth=none). See `foundry/references/zt-hashi-aap.md`.

```yaml
# instances.yaml
virtualmachines:
  - name: vscode
    image: devtools-ansible
    memory: 8G
    cores: 2
    image_size: 20Gi
    tags:
      - key: AnsibleGroup
        value: isolated
    services:
      - name: vscode
        ports:
          - port: 8080
            protocol: TCP
            targetPort: 8080
            name: vscode
    routes:
      - name: vscode
        host: vscode
        service: vscode
        targetPort: 8080
        tls: true
        tls_termination: Edge
    userdata: |-
      #cloud-config
      user: rhel
      password: ansible123!
      chpasswd: { expire: False }
      runcmd:
        - echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/50-cloud-init.conf
        - systemctl reload sshd
```

Setup stub (`setup-vscode.sh`): Configure code-server (0.0.0.0:8080, auth=none),
install cloud CLIs (AWS CLI, Terraform), populate ~/.aws/credentials, generate SSH key,
install ansible-builder, enable systemd linger.

### Keycloak (Container)

OIDC/SAML identity provider. Hostname must be set dynamically using GUID/DOMAIN.
See `foundry/references/zt-zero-trust-aap.md`.

```yaml
# instances.yaml (container on a host VM, managed via podman)
# Or as a standalone container:
containers:
  - name: keycloak
    image: registry.redhat.io/rhbk/keycloak-rhel9:24
    ports:
      - 8180
      - 8543
    environment:
      - name: KEYCLOAK_ADMIN
        value: admin
      - name: KEYCLOAK_ADMIN_PASSWORD
        value: ansible123!
      - name: KC_HTTP_ENABLED
        value: "true"
      - name: KC_HOSTNAME
        value: "keycloak-https-${guid}.${domain}"
    services:
      - name: keycloak-https
        port: 8543
    routes:
      - name: keycloak-https
        service: keycloak-https
        target_port: 8543
        tls: Edge
```

### NetBox (Container)

Infrastructure CMDB. Typically deployed via Docker Compose on a dedicated VM.
For simpler labs, can run as a standalone container. See `foundry/references/zt-zero-trust-aap.md`.

```yaml
containers:
  - name: netbox
    image: docker.io/netboxcommunity/netbox:latest
    ports:
      - 8000
    environment:
      - name: SUPERUSER_NAME
        value: admin
      - name: SUPERUSER_PASSWORD
        value: netbox
      - name: SUPERUSER_EMAIL
        value: admin@example.com
      - name: ALLOWED_HOSTS
        value: "*"
    services:
      - name: netbox
        port: 8000
    routes:
      - name: netbox
        service: netbox
        target_port: 8000
        tls: Edge
```

For production labs, NetBox is better deployed via Docker Compose on a dedicated VM
(includes PostgreSQL, Redis, worker). See the ZT lab's setup-netbox.sh for that pattern.

### Open Policy Agent (Container)

Stateless policy engine. No authentication by default. Policies loaded via bundles
or API. See `foundry/references/zt-zero-trust-aap.md`.

```yaml
containers:
  - name: opa
    image: docker.io/openpolicyagent/opa:latest
    ports:
      - 8181
    environment:
      - name: OPA_ARGS
        value: "run --server --addr=0.0.0.0:8181"
    services:
      - name: opa-http
        port: 8181
    routes:
      - name: opa-http
        service: opa-http
        target_port: 8181
        tls: Edge
```

When integrating with AAP platform-level policy enforcement, configure:
Settings -> Automation Execution -> Policy -> OPA Hostname, Port 8181.

### SPIRE Server (Container)

SPIFFE identity provider. Runs as server; SPIRE Agent runs on execution nodes.
See `foundry/references/zt-zero-trust-aap.md`.

```yaml
containers:
  - name: spire-server
    image: ghcr.io/spiffe/spire-server:latest
    ports:
      - 8081
    environment:
      - name: SPIRE_SERVER_ARGS
        value: "run"
    volumes:
      - name: spire-config
        mount_path: /opt/spire/conf/server
      - name: spire-data
        mount_path: /opt/spire/data
    services:
      - name: spire-server
        port: 8081
```

SPIRE Agent must also be deployed on AAP execution nodes. Trust domain should match
the lab's DNS domain (e.g., zta.lab). Workload attestation uses Unix PIDs or k8s.

### EDA Webhook Listener (Service)

Not a separate container. EDA webhook endpoint is built into AAP controller.
Add the port to firewall rules when using EDA with external event sources.

```yaml
# firewall.yaml addition
ingress:
  - port: 5000
    protocol: TCP
    # EDA webhook endpoint on AAP controller
```

## Reference Knowledge

When a user requests a service that maps to a known lab pattern, load the relevant
reference from `foundry/references/` for architecture guidance:
- Vault, OPA, SPIRE, EDA, IdM, Keycloak, NetBox -> `zt-zero-trust-aap.md`
- Vault, Terraform, VSCode, AWS, EE -> `zt-hashi-aap.md`

See `foundry/references/INDEX.md` for the full tag mapping.

## Important

- Match the YAML style and indentation of the existing instances.yaml
- Use the same route naming convention as existing routes
- Both VMs and containers need `routes:` sections for external access
- For VMs: include `networks: [default]` and `tags: [{key: AnsibleGroup, value: isolated}]`
- For VMs: include cloud-init userdata with `runcmd` to enable SSH password auth.
  Do NOT use `ssh_pwauth: true` (RHEL 9.5 sshd_config overrides it).
- ALWAYS use `|-` (literal block scalar) for userdata, NEVER `>-` (folded).
- AAP controller needs 32G memory and CA cert on reencrypt route (503 without it)
- Container service ports need a `name` field
- Container environment must be a flat dict
- `setup-automation/ansible.cfg` with `host_key_checking = False` is required
