#!/bin/sh

deploy() {
  ./setup.sh openfaas -r
  # ./setup.sh openwhisk -r
  ./setup.sh kubeless -r
  ./setup.sh fission -r
  ./setup.sh knative -r

  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_knative"
  echo "Knative:"
  kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_openfaas"
  echo "\nOpenFaaS:"
  kubectl get svc -n openfaas gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

  # export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_openwhisk"
  # echo "\nOpenWhisk:"
  # kubectl get svc -n openwhisk owdev-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_kubeless"
  echo "\nKubeless:"
  kubectl get svc nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  
  export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_fission"
  echo "\nFission:"
  kubectl get svc -n fission router -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
}

remove() {
  ./setup.sh knative -r -d
  ./setup.sh openfaas -r -d
  # ./setup.sh openwhisk -r -d
  ./setup.sh kubeless -r -d
  ./setup.sh fission -r -d
}

if [[ $1 = "-d" ]]
then
  remove
else
  deploy
fi
