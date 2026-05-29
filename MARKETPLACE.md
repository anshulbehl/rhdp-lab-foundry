# RHDP Lab Foundry

Claude Code plugin for forging Red Hat Demo Platform labs.

## Installation

### Add the Marketplace

```bash
/plugin marketplace add anshulbehl/rhdp-lab-foundry
```

### Install the Plugin

```bash
/plugin install foundry@rhdp-lab-foundry
```

### Prerequisites

Lab Foundry delegates to RHDP skills for content and catalog operations. Install these first:

```bash
# Add the RHDP marketplace (if not already added)
/plugin marketplace add rhpds/rhdp-skills-marketplace

# Install RHDP plugins
/plugin install showroom@rhdp-marketplace
/plugin install agnosticv@rhdp-marketplace
/plugin install health@rhdp-marketplace
```

## Updating

To pick up a new version, reinstall the plugin. The plugin system resolves the current version from the marketplace index:

```bash
/plugin marketplace update rhdp-lab-foundry
/plugin install foundry@rhdp-lab-foundry
```

Note: `/plugin` commands are only available in the Claude Code CLI (`claude` in a terminal), not the VSCode extension.

## Available Skills

| Skill | Description |
|:------|:------------|
| `/foundry:forge-lab` | Scaffold a new lab from requirements |
| `/foundry:add-service` | Add a VM, container, or route |
| `/foundry:add-module` | Add a workshop module |
| `/foundry:configure-infra` | Interactive infrastructure designer |
| `/foundry:validate-lab` | Validate and generate health checks |
| `/foundry:add-grading` | Generate solve/validate scripts |
| `/foundry:deploy-lab` | Prepare for RHDP deployment |
