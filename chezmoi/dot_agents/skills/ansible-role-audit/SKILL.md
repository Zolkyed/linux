---
name: ansible-role-audit
description: Audit Ansible roles for dead code, unused variables/secrets, orphaned template files, and unnecessary cross-role coupling. Use when asked to clean up, audit, or make Ansible roles "standalone" / "production ready", or to check for stale config, dead variables, or unused SOPS-encrypted secrets across a role or an entire roles/ directory.
---

# Ansible role audit

Systematic audit for Ansible roles: dead code, unused vars, orphaned files,
unused secrets, and cross-role coupling. Read the whole role tree — and, for
a repo-wide audit, all roles — before making judgment calls. Issues like
"this var is only used by one other role" don't show up from reading a
single file in isolation.

## 1. Unused default variables

For every var defined in `defaults/main.yml`, grep the role — and if
auditing more broadly, the whole `roles/` and `inventory/` tree — for other
references. A var used only on its own definition line is dead.

## 2. Orphaned template/file references

List every file under `templates/` and `files/`. Confirm each is referenced
by a `src:` in `tasks/main.yml` (or `handlers/`). Watch for false positives:
`ansible.builtin.copy` with `src: somedir/` copies a whole directory —
individual files inside it won't show up as literal string matches in
tasks, and that's correct, not orphaned.

## 3. Unused secrets (SOPS or similar encrypted vaults)

Variable *names* in a SOPS-encrypted YAML file are plaintext even though
values are encrypted (`key: ENC[...]`) — grep for names directly, no
decryption needed. Cross-check each vault-defined name against usage across
the repo. A name that only appears in its own vault file is dead and should
be removed from the vault.

Editing the vault itself requires the user's `sops`/age key access — don't
attempt to decrypt or re-encrypt without explicit permission. If decrypting
is blocked by a sandbox/permission classifier, stop and hand the user the
exact `sops` commands to run themselves rather than trying to route around
the block. If you do get permission and edit a vault file, never leave
plaintext at rest: write the plaintext to the real destination path (so
`sops -e -i` picks up the right creation rule) with a backup-and-rollback
trap around the encrypt step, and check for `*.sops.tmp.yml`-style leftover
files afterward — `sops -i` doesn't always clean up its temp file on every
filesystem (seen in practice on WSL/Windows-mounted paths).

## 4. Cross-role coupling

Grep every role for `appdata }}/<other-role-name>` path reaches, and
cross-reference each `container_name:` value against usage outside its
owning role's directory. Use word-boundary-safe matching — a naive
substring grep for `gluetun` will false-positive inside `gluetun-nsfw`,
which is actually a separate role's own independent container.

For every real hit, don't reflexively "fix" it — ask: **is this coupling
accidental, or does it reflect a genuine logical dependency?**

- **Necessary/correct coupling**: role B exists specifically to act on role
  A's resource — e.g. a DB-refresh role reading the same schema file the
  app role owns (so there's one source of truth and no drift risk), or a
  log-shipping/security role reading another service's log directory
  because that's literally its job. Don't split these apart. Duplicating
  state to "decouple" often trades a coupling problem for a correctness
  problem (schema/config drift between two copies), which is worse.
- **Accidental coupling**: role B reaches into role A's private files/vars
  only because it was convenient at write time, with no real reason B needs
  A specifically. Worth fixing — e.g. a variable that's conceptually shared
  infrastructure (a static public URL, an account ID) is often better
  promoted to a shared `group_vars`-level var than either duplicated across
  roles or reached into another role's `defaults/`.
- If two roles independently use the *same third-party tool/image* with no
  runtime interaction between them, that's not coupling at all — don't
  flag it.

## 5. Verify, don't just report

Before flagging anything as a finding, re-derive why with a fresh
grep/read — mechanical scripts produce false positives (generic
substrings, directory-copy patterns, two unrelated roles independently
using the same image). State the false positives you ruled out, not just
the real findings, so the user can trust the negative result too.

## 6. If testing changes live

When an audit leads to real edits (merging roles, moving ownership of a
resource between roles, deleting dead vars), prefer verifying end-to-end
before declaring done: render the actual templates, deploy for real
(locally if a safe target exists), check container/service health, and
exercise the real data path (query the API, hit the actual endpoint) —
not just `--syntax-check`. Syntax-check proves the YAML parses; it proves
nothing about whether the resulting stack actually serves data correctly.
