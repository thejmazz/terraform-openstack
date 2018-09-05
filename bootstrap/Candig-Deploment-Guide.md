# CanDIG Dev Environment

This deploys a private, ~~air-gapped~~, hybrid cloud consisting of

- Ubuntu VMs
- CoreOS VMs
- Docker Containers
- Swarm, Kubernetes
- Rancher 2
- Single shared storage backing multiple clusters (or multiple)

Requirements: 24gb ram, 20 vpus, 4 floating ips

You can design dev/staging/prod environments as alternative projects
(`deploy`ed via drone with alternative endpoints) or as concepts within the
cluster (e.g., suffixed K8s namespaces which could be managed by different
`IngressController`s sitting on specific nodes with specific security group +
routing rules)

It handles minutiae which may be encountered within certain OpenStack
environments depending on available backend services, their upgrades, etc.
Wouldn't streaming console serial logs into a shared cluster logging be nice?

- Configuring Docker and CNI networks within specific on premise IP ranges
- Configuring alternative external entrypoints into the system for

  * name_protocol_port_ig_cidr_eg_cidr
  * name_protocol_port_
  * name_protocol_ports_start_end_
  * ssh_TCP_22
  * https_433
  * http_80
  * dns_udp_53

- if desired, the ability to install from host or package manager

Currently, this primarily serves as a development environment for comparing
alternative infrastructure approaches with 100% self-hosted, open source, (MIT
licensed?, license checks in CI would be nice) software.

A big component of the design is the self-hosted CI/CD which enables rapid
development on a shared system. Each artifact that is enabled within the system
has metadata which directs to the config used to produce it. For example, VM images
would point towards an ansible playbook. Furthermore, security scans such as Claire
may be ran over containers before pushing towards a registry.

Systemd is the primary alternative orchestration service in comparison to
K8s, with configuration/data on the file system usually.

Templated, versioned, artifact which can be

The example development apps include

- VueJS + Apollo
- React + Relay Modern
- Webpack starter pack for isomorphic Node app

## Security

### Restricted and Auditing SSH Access

### Logging of source IPs for each request

- OpenTracing


## Debugging K8s Deployments

- verify labels on selectors are correct (helm template can help with this)
- confirm known network connections
- investigate DNS resolution within containers vs outside, etc
