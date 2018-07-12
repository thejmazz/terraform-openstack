# bootstrap

The goal of this module is to quickly launch a VM which can then let you keep
track of deployed infrastructure in Git. Whether you want to manage VMs, Docker
Swarm, or Kubernetes, or a mix of all of those, across multiple environments,
this is a good starting point. This launches an Ubuntu based stack using apt,
nginx, golang, and systemd.

## Requirements

This module assumes that:

- Nothing. The tenant can be empty.
- Well maybe not nothing. A flavor should exist.

On the client machine:

- the user has the Python `openstack` client
- the user has access to an OpenStack RC v3 file for the target tenant
- the user has `terraform`
- the user has `ssh-keygen`
- the user knows their `external_network_id` for the target tenant
  * `openstack network list --external --format value --column ID`
- the user knows which subnet their client machine exists on
  * for limiting access via security groups
  * for fixing conflicts with the interfaces the Docker daemon creates on the host
- the user has `ansible`, `ansible-playbook`, and `ansible-galaxy`
- the user has `terraform-inventory`

Optionally,

- the user may have `pget` installed for a quicker download of the Ubuntu image

It will deploy a single machine capable of

- running cfssl as a root CA
- running a Minio server (as a Terraform state backend)
- running a GitLab/Gitea server (as a Git server to store infrastructure configuration)
- running a Drone instance (as a CI server for deploys of infrastructure configuration)
- running an Atlantis instance

It is purposefully not managed by a container orchestration system. Rather it
uses (hopefully) more well know and simpler technologies:

- installs a Go environment onto the server, for `go get`ing binaries
- runs services in systemd. The idea is that `systemctl status` should inform
  an admin of everything relevant, and all debugging can be exercised through
  `journalctl`.
- installs Docker, but only for Drone

That is, someone who is familiar with `apt-get install` should be comfortable
reading and following these instructions (and feel confident they understand
what it does).

## Instructions

1. `terraform init` (set up a local backend `terraform.tfstate`)
2. Override defaults from `variables.tf` in `terraform.tfvars` if
   you desire. Variables can be passed at the command line as
   well.
3. Create a key: `ssh-keygen -t rsa -f ./bootstrap`
4. Plan:

    ```bash
    terraform plan \
    -var "external_network_id=$(openstack network list --external --format value --column ID)" \
    -var "external_network_name=$(openstack network list --external --format value --column Name)" \
    -var 'ssh_cidr_sources=["172.17.0.0/16", "172.16.0.0/12"]' \
    -var "public_key=$(cat bootstrap.pub)"
    ```

5. Apply with `terraform apply` using the same variables.
6. Download ansible roles (from ansible galaxy and github)

  ```bash
  ansible-galaxy install -r ./playbook/requirements.yml --roles-path=./playbook/roles
  ```

7. Run the playbook against the host terraform provisioned:

  ```bash
  ansible-playbook --inventory-file=$(which terraform-inventory) --user ubuntu --private-key ./bootstrap ./playbook/bootstrap.yml
  ```

  Alternatively, `-i "$(terraform output floating_ip),"` would have worked as well.

8. Access your new VM: `ssh ubuntu@$(terraform output floating_ip) -i ./bootstrap`


## Notes

- If you are modifying the playbook, a development workflow might look like:

  ```bash
  # edit playbook
  terraform apply
  ansible-playbook
  # fails, edit playbook again
  ansible-playbook # now we are re-running the playbook..
  # common problem: dist-upgrade runs again, updates docker, when docker installs via role, fails to downgrade
  # solution: only run dist-upgrade one time, or never rerun a playbook on the same host;
  # you can bring up a fresh server with:
  terraform taint openstack_compute_instance_v2.bootstrap
  # and then apply again, then run ansible-playbook again.
  # Is it worth making perfectly idempotent plays? (e.g. handling dist-upgrade problem)
  # A: No, if you plan to use ansible + packer to create launchable VMs
  # A: Yes, if you plan to keep using ansible to maintain state over time
  ```

- **When** you are modifying the playbook, corrected from above. Simply, you will. Configuring a VM idempotently is somewhat non-trivial:

  * there are unknown base configurations (example, we could launch off another image that already has changes, playbook happily works, but then fails on a vanilla Ubuntu)
  * dealing with installing languages (golang, python + pip, node + npm, etc) and packages for them
  * dealing with software updates on the OS (e.g. dist-upgrade brings in a new version, but you should be dist-upgrading to get security updates)
  * it can all break if someone goes in, `apt installs some stuff`, runs a playbook that depends on that...
  * Another packaging format exists which alleviates some of these concerns: containers.

- Notably, **I have not bothered making this playbook perfectly idempotent. I create a brand new VM every time when modifying the playbook.**

- Order as described [here](https://docs.ansible.com/ansible/2.5/user_guide/playbooks_reuse_roles.html):
    * Any `pre_tasks` defined in the play.
    * Any handlers triggered so far will be run.
    * Each role listed in `roles` will execute in turn. Any role dependencies defined in the roles `meta/main.yml` will be run first, subject to tag filtering and conditionals.
    * Any `tasks` defined in the play.
    * Any handlers triggered so far will be run.
    * Any `post_tasks` defined in the play.
    * Any handlers triggered so far will be run.


## TODOS

- [ ] Variables to use external services (e.g. an S3 compatible server, or existing GitLab)
- [ ] Volumes for important stateful data
- [ ] Ability to boostrap from a client PC
- [ ] Monitoring stack (prometheus)
- [ ] Logging stack (ELK + filebeat)
