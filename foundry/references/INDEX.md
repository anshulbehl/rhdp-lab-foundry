# Lab Reference Index

Tag-based index of real-world lab patterns extracted from production Summit labs.
Skills should load relevant references when a user's interview answers match these tags.

## How to Use

During `forge-lab` interview, match user answers to tags below. Load the referenced
file to inform blueprint selection, infrastructure design, and setup automation patterns.

Multiple tags can match. Load all matching references and synthesize.

## References

| Reference | Tags | Summary |
|:----------|:-----|:--------|
| [zt-zero-trust-aap.md](zt-zero-trust-aap.md) | vault, opa, spire, eda, splunk, idm, freeipa, security, identity, zero-trust, keycloak, netbox, central-node, multi-service-vm, incident-response | NIST 800-207 Zero Trust with AAP as PEP, OPA as PDP, Vault for dynamic credentials, SPIRE for workload identity, EDA for incident response |
| [zt-hashi-aap.md](zt-hashi-aap.md) | vault, terraform, ide, vscode, aws, cloud, hashicorp, execution-environment, api-driven, workflow, custom-credential-type | AAP + Terraform Enterprise + Vault Enterprise with VSCode IDE, AWS cloud integration, API-driven solve/validate |

## Tag Glossary

- **vault**: HashiCorp Vault for secrets, dynamic credentials, SSH CA
- **terraform**: Terraform Enterprise or Terraform CLI integration
- **opa**: Open Policy Agent for policy-as-code decisions
- **spire**: SPIFFE/SPIRE workload identity verification
- **eda**: Event-Driven Ansible (rulebooks, event streams, decision environments)
- **splunk**: Splunk for log aggregation, HEC, saved searches, alerts
- **idm/freeipa**: Red Hat IdM for DNS, Kerberos, LDAP, HBAC
- **keycloak**: OIDC/SAML identity provider
- **netbox**: NetBox CMDB for infrastructure source of truth
- **ide/vscode**: VSCode code-server as student development environment
- **aws/cloud**: AWS credential integration, EC2 dynamic inventory
- **central-node**: Single VM hosting multiple services via podman
- **api-driven**: Solve/validate using ansible.builtin.uri API calls instead of SSH
- **custom-credential-type**: AAP custom credential type schemas
- **workflow**: AAP workflow job templates with multi-node orchestration
- **execution-environment**: Custom EE build with ansible-builder
- **incident-response**: Automated detection and remediation chains
