---
name: foundry:configure-infra
description: Design or modify a lab's infrastructure configuration (instances.yaml, firewall.yaml, networks.yaml, ui-config.yml). Interactive infrastructure designer. Use when asked to "configure infrastructure", "update instances", "resize a VM", "change firewall rules", or "update ui-config".
context: main
model: claude-sonnet-4-6
---

# Configure Infrastructure - Interactive Infrastructure Designer

Read and modify a lab's infrastructure configuration files interactively.

## Capabilities

1. **Show current config**: Display instances.yaml in a readable summary table
2. **Resize**: Change VM memory, cores, or disk size
3. **Change image**: Update VM or container images
4. **Add/remove ports**: Update service port definitions and firewall rules
5. **Add/remove routes**: Update OpenShift route definitions
6. **Update ui-config**: Sync tabs with infrastructure changes
7. **Resource audit**: Calculate total memory, cores, storage and warn if exceeding platform limits

## Resource Limits

RHDP platform limits (approximate):
- Single lab: 32GB memory total (recommended), 64GB maximum
- Single VM: 16GB memory maximum
- Containers: lightweight, typically under 2GB each
- Storage: 100GB per VM maximum

## Central Node (Multi-Service VM) Pattern

Some labs consolidate many services onto a single VM instead of running separate
containers or VMs per service. This pattern is used when services need to:
- Share a local DNS server (e.g., FreeIPA running on the same host)
- Communicate over localhost or podman internal networking
- Share IPA client enrollment or Kerberos keytabs
- Reduce total VM count for resource-constrained environments

See `foundry/references/zt-zero-trust-aap.md` for a production example (22 services
on one 32GB VM).

### When to Recommend

Suggest a central node when the user needs 4+ services that have interdependencies,
or when total memory would exceed RHDP limits if each service had its own VM.

### Structure

A central node is a standard VM in instances.yaml with many services and routes.
The setup script uses podman to run containers on the VM, and systemd to manage
native services. The key template is `setup-central-configure.sh.j2`.

```yaml
# instances.yaml: central node definition
virtualmachines:
  - name: central
    image: rhel-9.5  # or a custom pre-baked image
    memory: 32G
    cores: 8
    image_size: 70Gi
    services:
      # List ALL services hosted on this VM
      - name: idm-https
        ports: [{port: 443, protocol: TCP, targetPort: 443}]
      - name: opa-http
        ports: [{port: 8181, protocol: TCP, targetPort: 8181}]
      # ... more services
    routes:
      # One route per externally-accessible service
      - name: idm-https
        host: idm-https
        service: idm-https
        targetPort: 443
        tls_termination: Edge
      # ... more routes
```

### Setup Script Generation

Use the template `templates/zero-touch/setup-automation/setup-central-configure.sh.j2`
to generate the central node configuration script. The template accepts:

- `central_services[]`: List of services, each with:
  - `name`: Service identifier
  - `type`: "podman" (container) or "systemd" (native service)
  - `image`: Container image (for podman type)
  - `ports`: Port mappings as "host:container" strings
  - `environment`: Key-value environment variables
  - `readiness_check`: Command or URL to verify service is ready
  - `depends_on`: List of service names that must be ready first

## Critical Format Rules

These rules prevent provisioning failures on RHDP. Violations cause silent
breakage (VMs boot but SSH never works, runner times out after 20 minutes).

**Userdata:**
- VM userdata MUST use `|-` (literal block scalar), NEVER `>-` (folded).
  The `>-` collapses cloud-init into one line, breaking YAML parsing.
- VM userdata MUST use `runcmd` to enable SSH password auth. Write
  `PasswordAuthentication yes` to `/etc/ssh/sshd_config.d/50-cloud-init.conf`
  and reload sshd. Do NOT use `ssh_pwauth: true` as it does not work on
  RHEL 9.5 images (the image's sshd_config overrides cloud-init's setting).

**Memory and images:**
- VM memory uses `G` (e.g., `32G`), container memory uses `Gi` (e.g., `2Gi`).
- AAP controller MUST have 32G memory (16G causes slow boot and SSH timeouts).
- AAP image: `aap-2.6-6-ceh-20260325` (proven working at Summit 2026).
- RHEL image: `rhel-9.5`.

**Routes and networking:**
- Both VMs and containers use `routes:` sections for external access.
- AAP controller route MUST use `reencrypt` with `tls_destinationCACertificate`
  containing the AAP CA cert. Without it, the router returns 503.
- Container routes use `Edge` TLS termination.
- Every VM MUST have `networks: [default]` explicitly listed.
- Every VM MUST have `tags: [{key: AnsibleGroup, value: isolated}]`.

**Containers:**
- Container environment must be a flat dict, not a list of {name, value}.
- Container ports: `{name, containerPort, protocol}` objects.
- Container service ports need a `name` field.

**Setup automation:**
- `setup-automation/ansible.cfg` with `host_key_checking = False` is required.
  Without it, `sshpass` cannot handle SSH host key checking.
- Repo URL must end with `.git` when ordering from RHDP catalog.

## Workflow

1. Read config/instances.yaml, firewall.yaml, ui-config.yml
2. Display current infrastructure summary
3. Ask what to change
4. Make the change, show the diff
5. Validate consistency (firewall matches services, ui-config matches routes)
