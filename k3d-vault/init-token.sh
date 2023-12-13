#!bash

$SHELL check-requirements.sh || exit 1

# Convenience so we don't have to repeat this for all our Vault commands.
export VAULT_ADDR=http://0.0.0.0:8200/

# Get a token for the pki_policy that we can hand to cert-manager.
VAULT_TOKEN=$(vault write -field=token /auth/token/create \
                          policies="pki_policy" \
                          no_parent=true no_default_policy=true \
                          renewable=true ttl=767h num_uses=0)

# Next, we need to save our Vault token in a sealed secret for cert-manager's
# later use. We'll use --dry-run to just write the YAML out

echo "==== Saving cert-manager token ===="
kubectl create secret generic --dry-run=client -o yaml \
        -n cert-manager my-secret-token \
        --from-literal="token=$VAULT_TOKEN" \
    | kubeseal \
        --controller-namespace=sealed-secrets \
        --format yaml > sealed-token.yaml
