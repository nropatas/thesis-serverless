#!/bin/sh

remote="false"
delete="false"

knative() {
  if [ $remote = "true" ]
  then
    export KUBECONFIG="clusters/eks/kubeconfig_knative"
  fi

  if [ $delete = "false" ]
  then
    echo "Setting up Knative..."
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.13.0/serving-crds.yaml
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.13.0/serving-core.yaml
    kubectl apply -f clusters/knative/istio-crds.yaml
    kubectl apply -f clusters/knative/istio-minimal.yaml
    kubectl apply -f clusters/knative/istio-knative-extras.yaml
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.13.0/serving-istio.yaml
  else
    echo "Deleting up Knative..."
    kubectl delete -f https://github.com/knative/serving/releases/download/v0.13.0/serving-istio.yaml
    kubectl delete -f clusters/knative/istio-knative-extras.yaml
    kubectl delete -f clusters/knative/istio-minimal.yaml
    kubectl delete -f clusters/knative/istio-crds.yaml
    kubectl delete -f https://github.com/knative/serving/releases/download/v0.13.0/serving-core.yaml
    kubectl delete -f https://github.com/knative/serving/releases/download/v0.13.0/serving-crds.yaml
  fi
}

openfaas() {
  config_file="openfaas.yaml"

  if [ $remote = "true" ]
  then
    export KUBECONFIG="clusters/eks/kubeconfig_openfaas"
    config_file="openfaas-rbac.yaml"
  fi

  if [ $delete = "false" ]
  then
    echo "Setting up OpenFaaS..."
    helm install metrics-server --namespace kube-system stable/metrics-server \
      --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}"
    kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
    kubectl apply -f clusters/openfaas/$config_file
  else
    echo "Deleting OpenFaaS..."
    kubectl delete -f clusters/openfaas/$config_file
    kubectl delete -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
    helm uninstall metrics-server -n kube-system
  fi
}

########################################################################################

if [ -z $1 ]
then
  echo "Please specify a platform"
  exit 1
fi

for flag in $@
do
  case $flag in
    -r) remote="true" ;;
    -d) delete="true" ;;
  esac
done

export KUBECONFIG="$HOME/.kube/config"

case $1 in
  "knative") knative ;;
  "openfaas") openfaas ;;
  *) echo "Invalid platform" ;;
esac
