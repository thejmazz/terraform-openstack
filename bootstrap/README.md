# bootstrap

The goal of this module is to quickly launch a VM which can then let you keep
track of deployed infrastructure in Git. Whether you want to manage VMs, Docker
Swarm, or Kubernetes, or a mix of all of those, across multiple environments,
this is a good starting point. This launches an Ubuntu based stack using apt,
docker, nginx, golang, and systemd. The workflow is terraform -> ansible ->
(git, minio, CI/CD).

## Vocabulary

- containers vs VMs
- reverse proxy
- network, subnet, router, internet gateway, security group
- configuration management
- infrastructure as code (Iac)
- release (rolling, blue/green via ansible vs k8s)
- backups
- restore
- auditing
- logging (RBAC?)
- monitoring

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
- running a Minio server (as a Terraform state backend, and DOS storage (for arbitrary files))
- running a Gitea server (as a Git server to store infrastructure configuration + ...code)
- running a Drone instance (as a CI server for deploys of infrastructure configuration)
  * this creates docker containers and networks on the node, so the local
    docker daemon should have its DNS configured

It is purposefully not managed by a container orchestration system. Rather it
uses (hopefully) more well know and simpler technologies:

- installs a Go environment onto the server, for `go get`ing binaries
- installs other services by downloading binaries
- runs services in systemd. The idea is that `systemctl status` should inform
  an admin of everything relevant, and all debugging can be exercised through
  `journalctl`.
- installs Docker, but only for Drone

That is, someone who is familiar with `apt-get install` should be comfortable
reading and following these instructions (and feel confident they understand
what it does). Some general skills you may want to review are:

- users and groups within linux (e.g. system vs. non-system users, what are uids and gids)
- ownership properties (user/group/other read/write/execute)
- `/etc/<app>` for configuration

## Instructions

1. `terraform init` (sets up a local backend in `terraform.tfstate`)
2. Override defaults from `variables.tf` in `terraform.tfvars` if
   you desire. Variables can be passed at the command line as
   well, using `-var "key=val"`.
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
9. Add the Root CA's certificate to your browser, for example for firefox:

  ```bash
  export CERT_DB=$HOME/.mozilla/firefox/<profile>
  export CERT_PATH=./playbook/cacerts/$(terraform output floating_ip)/etc/cfssl/ca.pem
  export CERT_NICK=my_bootstrap_ca
  certutil -A -i $CERT_PATH -n $CERT_NICK -t CT,c, -d $CERT_DB
  ```

  Check it is there with `certutil -L -n $CERT_NICK -d $CERT_DB`. You can
  delete it with `certutil -D -n $CERT_NICK -d $CERT_DB` (Or naively add a
  security exception ;)

10. Add the DNS server to your local configuration: add

  ```bash
  echo "nameserver $(terraform output floating_ip)"
  ```

  to the top of `/etc/resolv.conf`.

11. Visit `git.<domain>.<tld>`. You can install from there or submit the request yourself:

  ```bash
  export GITEA_PG_PASSWORD=password
  export GITEA_APP_NAME="Company Git"
  export GITEA_DOMAIN="git.domain.tld"

  curl -X POST -H "Content-Type: application/x-www-form-urlencoded" https://$GITEA_DOMAIN/install \
  --cacert "playbook/cacerts/$(terraform output floating_ip)/etc/cfssl/ca.pem" \
  --data-urlencode "db_type=PostgreSQL" \
  --data-urlencode "db_host=127.0.0.1:5432" \
  --data-urlencode "db_user=gitea" \
  --data-urlencode "db_passwd=$GITEA_PG_PASSWORD" \
  --data-urlencode "db_name=gitea" \
  --data-urlencode "ssl_mode=disable" \
  --data-urlencode "db_path=data/gitea.db" \
  --data-urlencode "app_name=$GITEA_APP_NAME" \
  --data-urlencode "repo_root_path=/home/git/gitea-repositories" \
  --data-urlencode "lfs_root_path=/var/lib/gitea/data/lfs" \
  --data-urlencode "run_user=git" \
  --data-urlencode "domain=$GITEA_DOMAIN" \
  --data-urlencode "ssh_port=22" \
  --data-urlencode "http_port=3000" \
  --data-urlencode "app_url=https://$GITEA_DOMAIN" \
  --data-urlencode "log_root_path=/var/lib/gitea/log" \
  --data-urlencode "smtp_host=" \
  --data-urlencode "smtp_from=" \
  --data-urlencode "smtp_user=" \
  --data-urlencode "smtp_passwd=" \
  --data-urlencode "enable_federated_avatar=off" \
  --data-urlencode "enable_open_id_sign_in=on" \
  --data-urlencode "enable_open_id_sign_up=on" \
  --data-urlencode "default_allow_create_organization=on" \
  --data-urlencode "default_enable_timetracking=on" \
  --data-urlencode "no_reply_address=noreply.example.org" \
  --data-urlencode "admin_name=" \
  --data-urlencode "admin_passwd=" \
  --data-urlencode "admin_confirm_passwd=" \
  --data-urlencode "admin_email="
  ```

12. Make a Gitea account - first account is admin. Make a test repo.
13. Visit `drone.<domain>.<tld>` and activate your test repo.
14. Test drone with the following `.drone.yml` in the test repo and push:

  ```yaml
  pipeline:
    ls:
      image: ubuntu
      commands:
        - ls -lah
  ```

  The pipeline should succeed (which means DNS/hosts are working inside
  containers as well as on the host).

## Notes

- To see list of available facts:

  ```bash
  - name:
    setup:
    register: setup
  - debug: "msg={{ setup }}"
  - debug: "msg={{ hostvars }}"
  ```

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
  * handling configuration being changed and then restarting a downstream service (e.g. systemd unit files)

- Order as described [here](https://docs.ansible.com/ansible/2.5/user_guide/playbooks_reuse_roles.html):
    * Any `pre_tasks` defined in the play.
    * Any handlers triggered so far will be run.
    * Each role listed in `roles` will execute in turn. Any role dependencies defined in the roles `meta/main.yml` will be run first, subject to tag filtering and conditionals.
    * Any `tasks` defined in the play.
    * Any handlers triggered so far will be run.
    * Any `post_tasks` defined in the play.
    * Any handlers triggered so far will be run.

- To quickly inspect a containers environment:

  ```bash
  docker inspect <container_name> | jq '.[] | .Config.Env'
  ```

## TODOS

- [ ] Backup and restore
- [ ] Variables to use external services (e.g. an S3 compatible server, or existing GitLab)
- [ ] Volumes for important stateful data
- [ ] Ability to boostrap from a client PC
- [ ] Monitoring stack (prometheus)
- [ ] Logging stack (ELK + filebeat)
