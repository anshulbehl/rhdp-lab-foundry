# RHDP Lab Foundry

Plugin framework for creating Red Hat Demo Platform labs. Composes with upstream RHDP skills (showroom, agnosticv, ftl, health) and adds scaffolding, infrastructure design, and provisioning health reporting.

## Lab Types

Three distinct lab architectures. Each skill must know which type it's working with.

### Zero-Touch Lab (zt-*)
Self-contained repo with infrastructure, automation, AND content. The RHDP runner provisions everything from config/instances.yaml.

Required structure:
- config/instances.yaml, networks.yaml, firewall.yaml
- setup-automation/main.yml + setup-*.sh per host
- runtime-automation/main.yml + module-NN/ directories
- content/ with Antora docs
- ui-config.yml, site.yml

### AgnosticV Catalog Item
Lightweight catalog entry inside an AgnosticV catalog repo. References a showroom repo for infrastructure. No config/ directory in the catalog item itself.

Required structure:
- common.yaml (env_type, cloud_provider, git references)
- dev.yaml, test.yaml, prod.yaml (deployment stage overrides)
- description.adoc

### Showroom-Only Lab
Documentation and optional runtime automation. Infrastructure is provided externally (e.g., shared OCP cluster).

Required structure:
- content/ with Antora docs
- runtime-automation/ (optional solve/validate)
- ui-config.yml, site.yml

## Composing with RHDP Skills

Lab Foundry delegates to upstream RHDP skills where appropriate, but handles
ZT-specific concerns itself. The RHDP showroom skills were designed for
standard Showroom/RHDP deployments and may generate Antora content that is
incompatible with zero-touch labs.

| Task | ZT Labs | Standard Showroom |
|:-----|:--------|:------------------|
| Generate AsciiDoc content | Lab Foundry generates ZT-compatible content directly | Delegate to showroom:create-lab |
| Create demo modules | Lab Foundry handles (ZT-specific structure) | Delegate to showroom:create-demo |
| Validate content quality | Lab Foundry validates ZT structure, then optionally delegate to showroom:verify-content | Delegate to showroom:verify-content |
| Build AgnosticV catalog | Delegate to agnosticv:catalog-builder | Delegate to agnosticv:catalog-builder |
| Validate catalog config | Delegate to agnosticv:validator | Delegate to agnosticv:validator |
| Generate solve/validate | Delegate to ftl:rhdp-lab-validator | Delegate to ftl:rhdp-lab-validator |
| Deployment health checks | Lab Foundry embedded reporter | Delegate to health:deployment-validator |

### Zero-Touch Antora Differences

ZT labs differ from standard Showroom in several ways:
- Use `zero-touch-site.yml` (or `default-site.yml`) instead of standard `site.yml`
- Variables use `${guid}` and `${domain}` via envsubst, not standard Antora attributes
- Content is served from a container init process, not a standalone Showroom deployment
- The `antora.yml` must have an `asciidoc.attributes` section with `environment_variables`
  for variable substitution to work
- Runtime automation scripts (setup/solve/validation) are shell scripts, not Ansible playbooks
  in the standard FTL sense

ALWAYS generate ZT-compatible content when lab_type is zero-touch. Do NOT delegate
content generation to showroom:create-lab for ZT labs.

To invoke RHDP skills: `Skill(skill="showroom:create-lab", args="...")`

If an RHDP skill is not installed, prompt the user:
"This requires the showroom plugin. Install with: /plugin install showroom@rhdp-marketplace"

## Infrastructure Conventions

### instances.yaml
- virtualmachines: list of VMs with name, image, memory, cores, services, routes, userdata
- containers: list of containers with name, image, ports, environment, volumes
- All VMs get cloud-init userdata for initial configuration
- Routes use TLS termination (Edge or Reencrypt)

### firewall.yaml
- Default: deny all egress, explicit ingress whitelist
- Common ports: 22 (SSH), 80/443 (HTTP/S), 3000 (Gitea), 8443 (AAP)

### ui-config.yml
- antora.modules: list workshop modules
- tabs: external and internal service URLs
- Variables: ${guid}, ${domain} for dynamic URLs

## Setup Script Conventions

Setup scripts MUST include:
1. Wait-for-ready checks before configuring services
2. Retry logic for API calls (especially AAP controller config)
3. Idempotent operations (safe to re-run)
4. Error reporting with context (not just exit code)

## Validation and Health Reporting

The validate-lab skill generates validation scripts that:
1. Check infrastructure health (VMs running, containers up, ports open)
2. Verify service accessibility (all ui-config.yml tabs reachable)
3. Report results via webhook (Slack, Mattermost, or custom endpoint)
4. Support skip configuration via .foundry-skip file

## Template Variables

Templates use Jinja2 syntax. Common variables:
- lab_name: human-readable lab name
- lab_repo_name: GitHub repo name (zt-ans-bu-* convention)
- lab_type: zero-touch | agnosticv | showroom-only
- product: ansible | openshift | rhel | multi-product
- services: list of service definitions
- modules: list of workshop module definitions
