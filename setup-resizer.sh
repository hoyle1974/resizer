#!/bin/bash

. resizer.config

GiteaResizer() {
echo "------------------- Setup Resizer mirror in Gitea"
curl -H "Content-Type: application/json" -d '{"name":"resizer-initial-setup", "scopes":["repo"]}' -u $GITEA_USERNAME:$GITEA_PASSWORD $GITEA_URL'/api/v1/users/gitea-admin/tokens' | tr ',' '\n' | grep sha1 | cut -f2 -d':' | cut -f2 -d'"' >> ./token
TOKEN=`cat token`
echo "Token: $TOKEN"
rm token

curl -X 'POST' \
  $GITEA_URL'/api/v1/repos/migrate' \
  -H "Authorization: token $TOKEN" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{
  \"auth_password\": \"$GITEA_PASSWORD\",
  \"auth_token\" : \"$TOKEN\",
  \"auth_username\": \"$GITEA_USERNAME\",
  \"clone_addr\": \"https://github.com/hoyle1974/resizer.git\",
  \"description\": \"Resizer Microservice\",
  \"issues\": true,
  \"labels\": true,
  \"lfs\": true,
  \"lfs_endpoint\": \"string\",
  \"milestones\": true,
  \"mirror\": true,
  \"mirror_interval\": \"10m0s\",
  \"private\": false,
  \"pull_requests\": true,
  \"releases\": true,
  \"repo_name\": \"resizer\",
  \"repo_owner\": \"gitea-admin\",
  \"service\": \"git\",
  \"uid\": 0,
  \"wiki\": true
}"
}


# https://api.gocd.org/current/#create-a-config-repo
ConfigRepo() {
echo "------------------- Setup Resizer build in GOCD"
curl $GOCD_URL'/go/api/admin/config_repos' \
  -H 'Accept:application/vnd.go.cd.v4+json' \
  -H 'Content-Type:application/json' \
  -X POST -d '{
    "id": "resizer",
    "plugin_id": "yaml.config.plugin",
    "material": {
      "type": "git",
      "attributes": {
        "url": "http://gitea-http.gitea.svc.cluster.local:3000/gitea-admin/resizer.git",
        "branch": "main",
        "auto_update": true
      }
    },
    "configuration": [
      {
       "key": "pattern",
       "value": "*.myextension"
     }
    ],
    "rules": [
      {
        "directive": "allow",
        "action": "refer",
        "type": "*",
        "resource": "*"
      }
    ]
  }'
}

GiteaResizer
ConfigRepo
