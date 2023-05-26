# Generate TLS

## CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -subj "/C=US/ST=OR/L=Portland/O=example/CN=Example Root CA" -out ca.crt

# Server Pair
openssl req -newkey rsa:2048 -nodes -keyout domain.key -subj "/C=US/ST=OR/L=Portland/O=example/CN=*.localhost" -out domain.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:vault-local.localdomain:localhost.localdomain,DNS:localhost,IP:127.0.0.1") -days 3650 -in domain.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out domain.crt

