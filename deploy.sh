#!/bin/sh

deploy() {
  ./setup.sh knative -r
  ./setup.sh openfaas -r
  ./setup.sh openwhisk -r
  ./setup.sh kubeless -r
  ./setup.sh fission -r

  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_knative"
  echo "Knative:"
  kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_openfaas"
  echo "OpenFaaS:"
  kubectl get svc -n openfaas gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_openwhisk"
  echo "OpenWhisk:"
  kubectl get svc -n openwhisk owdev-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_kubeless"
  echo "Kubeless:"
  kubectl get svc nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  
  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_fission"
  echo "Fission:"
  kubectl get svc -n fission router -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
}

remove() {
  ./setup.sh knative -r -d
  ./setup.sh openfaas -r -d
  ./setup.sh openwhisk -r -d
  ./setup.sh kubeless -r -d
  ./setup.sh fission -r -d
}

if [ $1 = "-d" ]
then
  remove
else
  deploy
fi
