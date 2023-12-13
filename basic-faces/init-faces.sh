linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: emissary
  annotations:
    linkerd.io/inject: enabled
---
apiVersion: v1
kind: Namespace
metadata:
  name: faces
  annotations:
    linkerd.io/inject: enabled
EOF

helm install emissary-crds -n emissary --create-namespace --wait \
     oci://registry-1.docker.io/dwflynn/emissary-ingress-crds-chart

helm install emissary-ingress -n emissary --wait \
     --set replicaCount=1 \
     datawire/emissary-ingress

helm install faces -n faces --wait \
     oci://registry-1.docker.io/dwflynn/faces-chart
