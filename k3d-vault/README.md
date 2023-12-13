# k3d-vault

The scripts here set up an environment with a k3d cluster and a Vault server
running on the same Docker network, mimicking a world where there's a secret
store outside Kubernetes that Kubernetes should use.

Run `bash init-world.sh` to set up the environment. **This will destroy any
existing k3d cluster named `argo-cluster` and any existing Docker container
named `vault`. **

Once this is done, your k3d cluster will be running, but empty except for a
Bitnami Sealed Secrets controller in the `sealed-secrets` namespace.

Run `bash init-token.sh` to create YAML for a SealedSecret of the Vault token
that you can use to set up cert-manager to communicate with Vault.
