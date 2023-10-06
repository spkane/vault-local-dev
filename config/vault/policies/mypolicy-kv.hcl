path "secret/data/dev/myteam/*" {
  capabilities = ["create", "update", "read", "patch"]
}

path "secret/metadata/dev/myteam/*" {
  capabilities = ["list", "read"]
}

