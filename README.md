# Real-world(ish) Initializers

This repo has initializer scripts to set up demos in real-world(ish) ways.

- [`k3d-vault`](k3d-vault/): Sets up a k3d cluster with a Vault server running
  _outside_ the cluster in the same Docker network

- [`basic-faces`](basic-faces/): Assumes you have a running Kubernetes cluster
  with working loadbalancer Services, and deploys Linkerd, Emissary, and the
  Faces demo in a basic configuration.
