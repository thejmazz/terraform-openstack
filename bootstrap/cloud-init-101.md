# Cloud-Config 101

## Verifying Cloud Init is Running

It can be useful to write out a file just to check if cloud init is even running:

```yaml
#cloud-config

write_files:
  - path: /opt/test.txt
    content: |
      wheeeeee
```

## Enabling Console Password Access

The following config lets you set the password for `ubuntu` while still
collecting ssh keys over the metadata service. You can specify some
`ssh_authorized_keys` here, yet still load more from the OpenStack metadata
service.

You should only use this if you are confident the user data is being
transmitted over a secure connection. Furthermore, it is not terribly difficult
to crack these hashed passwords.

This is incredibly useful when debugging conflicting CIDRs between interfaces
Docker creates and on premise networks.

```yaml
#cloud-config

# mkpasswd -m sha-512 password saltpepper
password: $6$saltpepper$mZ70s.b21Yp8gpQqslZBnEQE4jSs/niYZYvEaFftCXQKnpY4cgolCeKr0Otz0bFr.1C09zqNozjzUieGC.ArX0

# add some keys if you'd like, or let the metadata service take care of
# providing them (along with actually choosing a `--key-name` for the instance)
ssh_authorized_keys:
  - ssh-rsa AAAAB....
```

See below for examples which *do not work*.

These do not work to set a password for `ubuntu`:

```yaml
#cloud-config

# With this config you are totally locked out

users:
  - name: ubuntu
    # has no effect, `passwd -l ubuntu` still runs
    lock_passwd: false
    # mkpasswd -m sha-512 password saltpepper
    password: $6$saltpepper$mZ70s.b21Yp8gpQqslZBnEQE4jSs/niYZYvEaFftCXQKnpY4cgolCeKr0Otz0bFr.1C09zqNozjzUieGC.ArX0
```

Furthermore, if you do not specify the `ssh_authorized_keys`, cloud config will
not grab these from the OpenStack metadata service (and combined with `ubuntu`
password locked (grep for `passwd` in `/var/log/cloud-init.log`) you will be
entirely locked out):

```yaml
#cloud-config

# With this config you can log in over SSH but not on the console

users:
  - name: ubuntu
    lock_passwd: false
    # mkpasswd -m sha-512 password saltpepper
    password: $6$saltpepper$mZ70s.b21Yp8gpQqslZBnEQE4jSs/niYZYvEaFftCXQKnpY4cgolCeKr0Otz0bFr.1C09zqNozjzUieGC.ArX0
    ssh_authorized_keys:
      - ssh-rsa AAAAB...
```

The cloud-config `users` sections is really meant for adding extra users, in
which case you use `default` on the first item in the list (first item in list
is set as default, use string `default` to maintain OS defaut). In this case,
`lock_passwd: false` will actually work for the other users:

```yaml
#cloud-config

# With this config you can log in over SSH with `foo` user

users:
  - default
  - name: foo
    lock_passwd: false
    # mkpasswd -m sha-512 password saltpepper
    password: $6$saltpepper$mZ70s.b21Yp8gpQqslZBnEQE4jSs/niYZYvEaFftCXQKnpY4cgolCeKr0Otz0bFr.1C09zqNozjzUieGC.ArX0
```

## Debugging

See what you can with `openstack console log show <instance-name>`. If you can
get into the box, take a look at

- `journalctl -u cloud-*`
- `less /var/log/cloud-init.log`
