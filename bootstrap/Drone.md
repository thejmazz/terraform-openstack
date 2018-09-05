# Drone

## Adding a repo

```bash
curl -H "Authorization: Bearer $DRONE_TOKEN" $DRONE_SERVER/api/user/repos?all=true&flush=true
drone repo add user/name
```

## Deploy

```
drone deploy user/name <build> <env>
```

## OpenStack

A basic config:

```
terraform-plan:
    image: jmccann/drone-terraform:5.0-0.11.7
    actions:
      - validate
      - plan
      - apply
    secrets:
      # OpenStack Provider
      - OS_AUTH_URL
      - OS_USERNAME
      - OS_PASSWORD
      - OS_USER_DOMAIN_NAME
      - OS_PROJECT_ID
      # S3 Backend
      - AWS_ACCESS_KEY_ID
      - AWS_SECRET_ACCESS_KEY``yaml
```

Add your secrets to the repo:

```bash
# Source OpenStack V3 RC file first
repository=user/name
for name in "OS_AUTH_URL" "OS_USERNAME" "OS_PASSWORD" "OS_USER_DOMAIN_NAME" "OS_PROJECT_ID"; do
  eval value=\$$name

  drone secret add --repository=$repository --name $name --value $value
done

# As a one liner
for name in "OS_AUTH_URL" "OS_USERNAME" "OS_PASSWORD" "OS_USER_DOMAIN_NAME" "OS_PROJECT_ID"; do eval value=\$$name; drone secret add --repository=$repository --name $name --value $value; done

# If you have some yaml2json utility
for name in $(cat .drone.yml | yaml2json | jq -r '.pipeline.validate.secrets | .[]'); do
  eval value=\$$name

  drone secret add --repository=$repository --name $name --value $value
done

# other secrets:
# "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY"
```

## TODO

- [ ] Be able to plan from PR (need to annotate step with allowed events)
- [ ] PR status API for Gitea/GitLab
