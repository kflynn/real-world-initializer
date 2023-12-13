# basic-faces

The script here assumes that you have a Kubernetes cluster with working
loadbalancer Services, and deploys [Linkerd], [Emissary-ingress], and the
[Faces demo] in a basic configuration. Emissary and Faces are both meshed, and
if you point your browser at the `emissary-ingress` service in the `emissary`
namespace, you'll see

- The Linkerd Viz dashboard at `/`
- The Faces demo at `/faces/`
- The `face` workload at `/face/` -- this is necessary for the Faces demo to
  work! but you won't be pointing a browser directly to it.

Note: The configuration here does not configure anything fancy: no retries,
timeouts, circuit breaking, or any of that stuff. It's just the bare minimum
to get the demo working.

To set everything up, just run `bash init-faces.sh`.

[Faces demo]: https://github.com/BuoyantIO/faces-demo
[Linkerd]: https://linkerd.io
[Emissary-ingress]: https://www.getambassador.io/docs/latest/topics/install/install-ambassador-oss/
