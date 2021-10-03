path "secret/data/dev/myteam/*" {
  capabilities = ["create", "update", "read"]
}

path "secret/metadata/dev/myteam/*" {
  capabilities = ["list", "read"]
}

