---
name: foundry:add-module
description: Add a new workshop module to a lab. Creates content pages, runtime-automation stubs, and updates navigation. Delegates content writing to showroom:create-lab. Use when asked to "add a module", "add a section", "add a new exercise", or "add a lab chapter".
context: main
model: claude-sonnet-4-6
---

# Add Module - Add a Workshop Module

Adds a new numbered module to an existing lab with content page, runtime-automation stubs, and navigation update.

## Workflow

1. Read existing modules to determine next number and style
2. Ask: What is this module about? (title and brief description)
3. Create content page: content/modules/ROOT/pages/{NN}-{slug}.adoc
4. Create runtime-automation directory: runtime-automation/module-{NN}/
5. Create stubs: setup-control.sh, solve-control.sh, validation-control.sh
6. Update content/modules/ROOT/nav.adoc with new module entry
7. Update .foundry.yml modules list

## Delegation

If showroom:create-lab is available, offer to generate full module content:
"Want me to generate detailed hands-on content for this module? I'll use the showroom:create-lab skill."

If the user accepts, invoke: `Skill(skill="showroom:create-lab", args="Generate module {NN}: {title} for lab {lab_name}. Context: {services available, previous modules}")`
