#!bash

$SHELL check-requirements.sh || exit 1

inspect_cert () {
  sub_selector='\(.extensions.subject_key_id | .[0:16])... \(.subject_dn)'
  iss_selector='\(.extensions.authority_key_id | .[0:16])... \(.issuer_dn)'

  step certificate inspect --format json \
    | jq -r "\"Issuer:  $iss_selector\",\"Subject: $sub_selector\""
}

# Kill anything lingering from before...
docker kill vault
k3d cluster delete argo-cluster

# If anything fails after this, bail.
set -e

# Fire up our cluster. Use the "argo-network" Docker network, expose ports 80
# & 443 to the host network, and disable local-storage, traefik, and
# metrics-server.
echo "==== Creating k3d cluster ===="
k3d cluster create argo-cluster \
    --network=argo-network \
    -p "80:80@loadbalancer" -p "443:443@loadbalancer" \
    --k3s-arg '--disable=local-storage,traefik,metrics-server@server:*;agents:*'

# ...then run Vault in a container, attached to the same network as our
# cluster. Important things here:
# -dev: use development mode
# -dev-listen-address: listen on all interfaces, not just localhost
# -dev-root-token-id: set the root token (AKA password) to something we know
echo "==== Starting Vault ===="
docker run \
       --detach \
       --rm --name vault \
       -p 8200:8200 \
       --network=argo-network \
       --cap-add=IPC_LOCK \
       hashicorp/vault \
       server \
       -dev -dev-listen-address 0.0.0.0:8200 \
       -dev-root-token-id my-token

# Convenience so we don't have to repeat this for all our Vault commands.
export VAULT_ADDR=http://0.0.0.0:8200/

# Give Vault a few seconds to get ready.
sleep 5

# Configure Vault. Log in using the oh-so-secret root token, then enable the
# PKI secrets engine, and tune it to have a maximum lease of 2160 hours (90
# days).
echo "==== Logging into Vault (at $VAULT_ADDR) ===="
vault login my-token

echo "==== Configuring Vault ===="
vault secrets enable pki
vault secrets tune -max-lease-ttl=2160h pki

# Configure Vault's PKI engine to use the URLs that cert-manager will expect.
vault write pki/config/urls \
   issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
   crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"

# Finally, create a policy that allows pretty much unrestricted access to the
# PKI secrets engine...
echo 'path "pki*" {  capabilities = ["create", "read", "update", "delete", "list", "sudo"]}' \
   | vault policy write pki_policy -

# Finally, tell Vault to actually create our Linkerd trust anchor. This cert
# only exists within Vault, we're explicitly giving it the common name of the
# Linkerd trust anchor ("root.linkerd.cluster.local"), it uses our maximum TTL
# of 2160 hours, and we want Vault to generate it using elliptic-curve crypto.
#
# The "-field=certificate" argument tells Vault to output only the
# certificate, so we can inspect it. This is safe because there's no secret
# information in the certificate.

echo "==== Creating trust anchor ===="
CERT=$(vault write -field=certificate pki/root/generate/internal \
      common_name=root.linkerd.cluster.local \
      ttl=2160h key_type=ec)

echo "Trust anchor certificate:"
echo "$CERT" | inspect_cert

# And, finally, we need the address of the Vault server so that we can tell
# cert-manager where to find it. We can get that from Docker.

VAULT_DOCKER_ADDRESS=$(docker inspect argo-network \
                       | jq -r '.[0].Containers | .[] | select(.Name == "vault") | .IPv4Address' \
                       | cut -d/ -f1)

echo $VAULT_DOCKER_ADDRESS > vault-address.txt
echo Vault is running at ${VAULT_DOCKER_ADDRESS} -- saved in vault-address.txt

helm repo add bitnami-labs https://bitnami-labs.github.io/sealed-secrets/
helm install -n sealed-secrets --create-namespace --wait \
     sealed-secrets-controller bitnami-labs/sealed-secrets
