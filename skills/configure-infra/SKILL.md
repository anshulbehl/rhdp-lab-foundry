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

## Workflow

1. Read config/instances.yaml, firewall.yaml, ui-config.yml
2. Display current infrastructure summary
3. Ask what to change
4. Make the change, show the diff
5. Validate consistency (firewall matches services, ui-config matches routes)
