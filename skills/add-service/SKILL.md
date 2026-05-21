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
| RHEL node | vm | rhel93 | 22 | 4GB, 2 cores |

## Actions

1. **Add to instances.yaml**: Insert the VM or container definition following existing patterns
2. **Add to firewall.yaml**: Add ingress rules for the service's ports
3. **Add to ui-config.yml**: Add a tab entry if the service has a web UI
4. **Add setup stub**: Create a setup script stub in setup-automation/ if needed
5. **Update .foundry.yml**: Add the service to the services list

## Important

- Match the YAML style and indentation of the existing instances.yaml
- Use the same route naming convention as existing routes
- For containers, always include a restart policy
- For VMs, include cloud-init userdata for SSH key injection
