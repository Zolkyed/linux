# Ansible

When an Ansible command fails or its output is incomplete, inspect
`ansible/.ansible/logs/ansible.log`, starting with the most recent entries.

After every Ansible playbook run, always inspect the most recent entries in
`ansible/.ansible/logs/ansible.log` for failures before reporting the result.
Never expose secrets or paste sensitive log content into responses.
