The instruction for Istio installation on Knative official site does not work. (Updated on 9 Mar 2020)

The 3 `ymal` files in this directory were generated by a script from https://github.com/knative/serving/tree/master/third_party/istio-1.4.4.

```
kubectl apply -f istio-crds.yaml
kubectl apply -f istio-minimal.yaml
kubectl apply -f istio-knative-extras.yaml
```