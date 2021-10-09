# Vault for Local Development

This is a docker compose setup for development work using Vault and Consul.

* FORKED from:
    * https://github.com/tolitius/cault

## Start Consul and Vault

```
export VAULT_ADDR='https://127.0.0.1:8200'
export VAULT_CAPATH="${PWD}/certs/ca.crt"
docker compose up -d
```

* [Vault UI](https://127.0.0.1:8200/ui)
* [Consul UI](http://127.0.0.1:8500/ui)

## Getting Vault Ready

* **NOTE**: It is a good idea to use the same version of the vault CLI as we are using for the vault server!

### Bootstrap

You can Bootstrap Vault via the [Vault UI](https://127.0.0.1:8200/ui) or the command line.

### Command Line

* Run `vault operator init` to create the unseal keys and initial root token.
  * If you see `* Vault is already initialized` then you have done this already.
  * Take a note of these! If you lose, you will need to start again.
* Run `vault operator unseal` three times in a row, giving Vault a different one of the 5 unseal keys.
  * The output will contain a line that starts with `Unseal Progress`. You want this line to completely go away and for the line `Sealed` to read `false`.
* After vault is unsealed, run `vault login` with the Initial Root Token that you got after running `vault operator init` earlier.

### Backup & Restore

* **NOTE**: This container does not persist ANY data as the consul node is in dev mode.

* `docker compose pause` and `docker compose unpause` are the only ways that you can stop the containers from running and still keep the data around without backing up and restoring the data. This does not survive a reboot, meaning you will need to restore and unseal after containers stop.

#### Backup

* If you want to save the data for later use, install the consul client locally and then try:
  * `consul snapshot save backups/vault-consul-backup-$(date +%Y%m%d%H%M).snap`

#### Restore

* You can then restore with something like this:
  * `consul snapshot restore ./backups/vault-consul-backup-202110021214.snap`

## README from forked repo:

Consul and Vault are started together in two separate, but linked, docker containers.

Vault is configured to use a `consul` [secret backend](https://www.vaultproject.io/docs/secrets/consul/).

---

- [Vault for Local Development](#vault-for-local-development)
  - [Start Consul and Vault](#start-consul-and-vault)
  - [Getting Vault Ready](#getting-vault-ready)
    - [Bootstrap](#bootstrap)
    - [Command Line](#command-line)
    - [Backup & Restore](#backup--restore)
      - [Backup](#backup)
      - [Restore](#restore)
  - [README from forked repo:](#readme-from-forked-repo)
  - [Start Consul and Vault](#start-consul-and-vault-1)
  - [Getting Vault Ready](#getting-vault-ready-1)
    - [Init Vault](#init-vault)
    - [Unsealing Vault](#unsealing-vault)
    - [Auth with Vault](#auth-with-vault)
  - [Making sure it actually works](#making-sure-it-actually-works)
    - [Watch Consul logs](#watch-consul-logs)
    - [Writing / Reading Secrets](#writing--reading-secrets)
    - [Response Wrapping](#response-wrapping)
      - [System backend](#system-backend)
      - [Cubbyhole backend](#cubbyhole-backend)
  - [Troubleshooting](#troubleshooting)
    - [Bad Image Caches](#bad-image-caches)
  - [License](#license)

## Start Consul and Vault

```bash
docker-compose up -d
```

## Getting Vault Ready

Login to the Vault image:

```bash
docker exec -it cault_vault_1 sh
```

Check Vault's status:

```bash
$ vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            n/a
HA Enabled         true
```

Because Vault is not yet initialized (`Initialized  false`), it is sealed (`Sealed  true`), that's why Consul will show you a sealed critial status:

<p align="center"><img src="doc/img/sealed-vault.png"></p>

### Init Vault

```bash
$ vault operator init
Unseal Key 1: dW2PXpPdjWZvXCUvE/GWxJ+CdeEp6SziEKh6xNYRpB8k
Unseal Key 2: 5K52IOOU+rZf+6Aj7PBOTclnL80Ftb1Wta1GbrJDWX8f
Unseal Key 3: ykK/Q5Il7OOp/qKTdT75U1q6EDzMo2LkM0KRWv7I11Lb
Unseal Key 4: /1EVEn1UDG4LbqI2h5MQPWRI1wpCbirELJyVBo+D2QR1
Unseal Key 5: H47Vch2d0AxuA43kxOlW+MzC/YtjoGU8wCoZLDmRg29r

Initial Root Token: s.1ee2zxWvX43sAwjlcDaSGGSC

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

notice Vault says:

> you must provide at least 3 of these keys to unseal it again

hence it needs to be unsealed 3 times with 3 different keys (out of the 5 above)

### Unsealing Vault

```bash
$ vault operator unseal
Unseal Key (will be hidden):
Key                Value
---                -----
...
Sealed             true
Unseal Progress    1/3

$ vault operator unseal
Unseal Key (will be hidden):
Key                Value
---                -----
...
Sealed             true
Unseal Progress    2/3

$ vault operator unseal
Unseal Key (will be hidden):
Key                    Value
---                    -----
...
Initialized            true
Sealed                 false
...
Active Node Address    <none>
```

the Vault is now unsealed:

<p align="center"><img src="doc/img/unsealed-vault.png"></p>

### Auth with Vault

We can use the `Initial Root Token` from above to auth with the Vault:

```bash
$ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.1ee2zxWvX43sAwjlcDaSGGSC
token_accessor       shMBI822edbRUYTo8mW54mdB
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

---

All done: now you have both Consul and Vault running side by side.

## Making sure it actually works

From the host environment (i.e. outside of the docker image):

```bash
alias vault='docker exec -it cault_vault_1 vault "$@"'
```

This will allow to run `vault` commands without a need to login to the image.

> the reason commands will work is because you just `auth`'ed (logged into Vault) with a root token inside the image in the previous step.

### Watch Consul logs

In one terminal tail Consul logs:

```bash
$ docker logs cault_consul_1 -f
```

### Writing / Reading Secrets

In the other terminal run vault commands:

```bash
$ vault write -address=http://127.0.0.1:8200 cubbyhole/billion-dollars value=behind-super-secret-password
```
```
Success! Data written to: cubbyhole/billion-dollars
```

Check the Consul log, you should see something like:

```bash
2016/12/28 06:52:09 [DEBUG] http: Request PUT /v1/kv/vault/logical/a77e1d7f-a404-3439-29dc-34a34dfbfcd2/billion-dollars (199.657µs) from=172.28.0.3:50260
```

Let's read it back:

```bash
$ vault read cubbyhole/billion-dollars
```
```
Key             	Value
---             	-----
value           	behind-super-secret-password
```

And it is in fact in Consul:

<p align="center"><img src="doc/img/vault-value-in-consul.png"></p>

and in Vault:

<p align="center"><img src="doc/img/secret-in-vault-ui.png"></p>

(this is from Vault's own UI that is enabled in this image)

### Response Wrapping

> _NOTE: for these examples to work you would need [jq](https://stedolan.github.io/jq/) (i.e. to parse JSON responses from Vault)._

> _`brew install jq` or `apt-get install jq` or similar_

#### System backend

Running with a [System Secret Backend](https://www.vaultproject.io/api/system/index.html).

Export Vault env vars for the local scripts to work:

```bash
$ export VAULT_ADDR=http://127.0.0.1:8200
$ export VAULT_TOKEN=s.1ee2zxWvX43sAwjlcDaSGGSC  ### root token you remembered from initializing Vault
```

At the root of `cault` project there is `creds.json` file (you can create your own of course):

```bash
$ cat creds.json

{"username": "ceo",
 "password": "behind-super-secret-password"}
```

We can write it to a "one time place" in Vault. This one time place will be accessible by a "one time token" Vault will return from a
`/sys/wrapping/wrap` endpoint:

```bash
$ token=`./tools/vault/wrap-token.sh creds.json`

$ echo $token
s.sMFwpg8DBYh0NXbXqjLJTNKN
```

You can checkout [wrap-token.sh](tools/vault/wrap-token.sh) script, it uses `/sys/wrapping/wrap` Vault's endpoint
to secretly persist `creds.json` and return a token for it that will be valid for 60 seconds.

Now let's use this token to unwrap the secret:

```bash
$ ./tools/vault/unwrap-token.sh $token

{"password": "behind-super-secret-password",
 "username": "ceo" }
```

You can checkout [unwrap-token.sh](tools/vault/unwrap-token.sh) script, it uses `/sys/wrapping/unwrap` Vault's endpoint

Let's try to use the same token again:

```bash
$ ./tools/vault/unwrap-token.sh $token
["wrapping token is not valid or does not exist"]
```

i.e. Vault takes `one time` pretty seriously.

#### Cubbyhole backend

Running with a [Cubbyhole Secret Backend](https://www.vaultproject.io/docs/secrets/cubbyhole/index.html).

Export Vault env vars for the local scripts to work:

```bash
$ export VAULT_ADDR=http://127.0.0.1:8200
$ export VAULT_TOKEN=s.1ee2zxWvX43sAwjlcDaSGGSC  ### root token you remembered from initializing Vault
```

Create a cubbyhole for the `billion-dollars` secret, and wrap it in a one time use token:

```bash
$ token=`./tools/vault/cubbyhole-wrap-token.sh /cubbyhole/billion-dollars`
```

let's look at it:

```bash
$ echo $token
s.T3GT2dGb8bUuJtSEenxnZick
```

looks like any other token, but it is in fact a _one time use_ token, only for this cobbyhole.

Let's use it:

```bash
$ curl -s -H "X-Vault-Token: $token" -X GET $VAULT_ADDR/v1/cubbyhole/response
```
```json
{
  "request_id": "f0cf41a6-d971-69be-4eee-c7137376a755",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": {
    "response": "{\"request_id\":\"083429a1-2956-39f0-a402-628b6e346ac0\",\"lease_id\":\"\",\"renewable\":false,\"lease_duration\":0,\"data\":{\"value\":\"behind-super-secret-password\"},\"wrap_info\":null,\"warnings\":null,\"auth\":null}"
  },
  "wrap_info": null,
  "warnings": [
    "Reading from 'cubbyhole/response' is deprecated. Please use sys/wrapping/unwrap to unwrap responses, as it provides additional security checks and other benefits."
  ],
  "auth": null
}
```

_(notice: that "cubbyhole/response" is deprecated, use the `system` backend instead. example is in the section above)_

Let's try to use it again:

```bash
$ curl -s -H "X-Vault-Token: $token" -X GET $VAULT_ADDR/v1/cubbyhole/response
```
```json
{"errors":["permission denied"]}
```

Vault takes `one time` pretty seriously.

## Troubleshooting

### Bad Image Caches

In case there are some stale / stopped cached images, you might get connection exceptions:

```clojure
failed to check for initialization: Get v1/kv/vault/core/keyring: dial tcp i/o timeout
```

```clojure
reconcile unable to talk with Consul backend: error=service registration failed: /v1/agent/service/register
```

you can purge stopped images to solve that:

```bash
docker rm $(docker ps -a -q)
```

## License

Copyright © 2019 tolitius

Distributed under the Eclipse Public License either version 1.0 or (at your option) any later version.
