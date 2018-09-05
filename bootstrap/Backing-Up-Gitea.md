1. Stop gitea

```
sudo systemctl stop gitea
```

2. Backup gitea postgres dump into minio

```
sudo su - git
PGPASSWORD=password pg_dump -h localhost -U gitea gitea | gzip > pg_dumps/gitea.$(date -u +"%Y-%m-%dT%H:%M:%SZ").sql.gz
mc mb local/gitea-pg-dumps
mc cp ./pg_dumps/*.sql.gz local/gitea-pg-dumps/
```

3. Backup Drone sqlite dump into minio

```
export DRONE_SQLITE=drone.$(date -u +"%Y-%m-%dT%H-%M-%SZ").sqlite.gz
docker run --rm --volumes-from drone-server ubuntu cat /var/lib/drone/drone.sqlite | gzip > $DRONE_SQLITE
mc cp $DRONE_SQLITE local/drone-sqlite/$DRONE_SQLITE
```

To restore drone with an sqlite backup, `COPY drone.sqlite /var/lib/drone.sqlite`.

5. Stop server

```
openstack server stop bootstrap2
```

4. Make image of /var/lib/gitea volume

```
openstack image create --private --volume minio_var_lib_minio minio_var_lib_minio_$(date -u +"%Y-%m-%dT%H-%M-%SZ")
```

5. Make image of /home/git/gitea-repositories volume
6. Make image of /var/lib/minio volume

```
sudo rsync -azvP /var/lib/gitea/ /mnt/vdb/
sudo rsync -azvP /home/git/gitea-repositories/ /mnt/vdc/
sudo rsync -azvP /var/lib/minio/ /mnt/vdd
```


Make volumes for

1. `/var/lib/gitea`
2. `/home/git/gitea-repositories`
3. `/var/lib/postgres`
4. `/var/lib/minio`

Stop the `gitea` service.

Log into the postgres DB to see current data:

```bash
# Example as the git user
sudo su - git
# Use --password or -W for password promt, or set PGPASSWORD ahead of time
psql -h localhost -d gitea -U gitea --password

# Example as the postgres user with peer authentication
sudo su - postgres
psql -d gitea -U postgres

# In the postgres prompt
select id,email,name from public.user;
```

Create a dump of the database using an account with enough priviliges.
Depending on the your setup, the owner of the database (`gitea`) may be
sufficient, or you may use the admin `postgres` account. You can double check
by comparing checksums of the resultant dump files.

Notably, use `date -u` to get UTC formatted dates (suffixed with `Z`).

```bash
sudo su - git
PGPASSWORD=password pg_dump -h localhost -U gitea gitea | gzip > pg_dumps/gitea.$(date -u +"%Y-%m-%dT%H:%M:%SZ").sql.gz

# Upload to minio
mc mb local/gitea-pg-dumps
mc cp --recursive ./pg_dumps/ local/gitea-pg-dumps/
```

Format and mount all the new volumes. Stop the `postgres` service befor copying
`/var/lib/postgres`.  We will use `rsync` since it has archival options which
can preserve uids/gids/permissions:

```bash
# archive, compress, verbose, and progress
sudo rsync -azvP /var/lib/gitea/ /mnt/var/lib/gitea
sudo rsync -azvP /home/git/gitea-repositories /mnt/home/git/gitea-repositories
sudo rsync -azvP /var/lib/postgresql/ /mnt/var/lib/postgresql
sudo rsync -azvP /var/lib/minio/ /mnt/var/lib/minio
```

WARNING

If you attach 4 volumes, `/dev/vdb` through `e`, then unmount+delete `d`, then
restart the server, `e` will become `d` but show up as `/dev/vde` on the
OpenStack UI.
