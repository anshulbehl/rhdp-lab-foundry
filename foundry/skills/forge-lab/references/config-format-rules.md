# RHDP Config Format Rules

These rules are non-negotiable. Violating ANY of them causes provisioning failure.

## File-Level Rules

| File | Rule |
|:-----|:-----|
| networks.yaml | Flat list at root. NO `networks:` key. Exactly `---\n- name: default` |
| firewall.yaml | Flat `ingress:` / `egress:` at root. `- ports:` at same indent level |
| secrets.yaml | Copy from template verbatim. NEVER generate. NEVER write `secrets: []` |
| ansible.cfg | Must exist in setup-automation/. `host_key_checking = False` |

## instances.yaml Rules

| Field | Correct | Wrong |
|:------|:--------|:------|
| AAP image | `aap-2.6-6-ceh-20260325` | `base-zero-aap-*` or any variant |
| RHEL image | `rhel-9.5` | `rhel93` or `rhel-93` |
| VM memory | `32G` (AAP), `4G` (RHEL) | `32Gi`, `4Gi` |
| Container memory | `4Gi` (Gitea) | `4G` |
| Tags | `- key: AnsibleGroup\n  value: isolated` | `- AnsibleGroup: control` |
| Networks | `networks:\n  - default` on every VM | Missing or omitted |
| Userdata scalar | `userdata: \|-` | `userdata: >-` |
| SSH auth | `runcmd:\n  - echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/50-cloud-init.conf\n  - systemctl reload sshd` | `ssh_pwauth: true` or `sed` |
| Userdata user | Must include `user: rhel\npassword: ansible123!\nchpasswd: { expire: False }` | Missing user/password |
| Service ports | `ports:\n  - port: 443\n    protocol: TCP\n    targetPort: 443\n    name: control-https` | `port: 443` (singular, flat) |
| AAP route | `tls_termination: reencrypt` with `tls_destinationCACertificate` | Missing CA cert |
| Route name | `control-https` | `control` |
| Container env | Flat dict: `KEY: "value"` | List: `- name: KEY\n  value: value` |
| Container routes | Required for external access | Omitting routes |

## Setup Script Rules

| Rule | Detail |
|:-----|:-------|
| Two-phase pattern | Phase 1: bootstrap (ansible.cfg + collections). Phase 2: configure AAP |
| Phase 1 | Uses `set -euo pipefail` (safe, no curl) |
| Phase 2 | NO `set -euo pipefail` (curl wait loop must survive) |
| AAP host | `https://localhost` (port 443, NOT 8443) |
| Collection install | `ansible-galaxy collection install -r requirements.yml` with AH token |
| Collection fallback | Symlink `awx.awx` as `ansible.controller` if Hub unavailable |
| OAuth token | Required for `ansible.controller` modules on AAP 2.6 Gateway |
| Module defaults | `group/ansible.controller.controller` with `validate_certs: false` |
| Credential match | Username/password MUST match VM userdata user/password |

## ui-config.yml Rules

| Rule | Detail |
|:-----|:-------|
| Tabs | `external: false` for iframe embedding |
| URLs | Trailing slash: `https://control-${guid}.${domain}/` |
| Module format | `name:`, `label:`, `solveButton:` |
