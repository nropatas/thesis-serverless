#!/bin/sh

remote="false"
delete="false"
proj_dir=$(pwd)

knative() {
  if [ $remote = "true" ]
  then
    export KUBECONFIG="${proj_dir}/clusters/eks/kubeconfig_knative"
  fi

  if [ $delete = "false" ]
  then
    echo "Setting up Knative..."

    helm install metrics-server --namespace kube-system stable/metrics-server \
      --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}"

    kubectl apply -f https://github.com/knative/serving/releases/download/v0.13.0/serving-crds.yaml
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.13.0/serving-core.yaml
    kubectl apply -f clusters/knative/istio-crds.yaml
    kubectl apply -f clusters/knative/istio-minimal.yaml
    kubectl apply -f clusters/knative/istio-knative-extras.yaml
    kubectl apply -f https://github.com/knative/serving/releases/download/v0.13.0/serving-istio.yaml
  else
    echo "Deleting Knative..."
    kubectl delete -f https://github.com/knative/serving/releases/download/v0.13.0/serving-istio.yaml
    kubectl delete -f clusters/knative/istio-knative-extras.yaml
    kubectl delete -f clusters/knative/istio-minimal.yaml
    kubectl delete -f clusters/knative/istio-crds.yaml
    kubectl delete -f https://github.com/knative/serving/releases/download/v0.13.0/serving-core.yaml
    kubectl delete -f https://github.com/knative/serving/releases/download/v0.13.0/serving-crds.yaml
    helm uninstall metrics-server -n kube-system
  fi
}

openfaas() {
  config_file="openfaas.yaml"

  if [ $remote = "true" ]
  then
    export KUBECONFIG="${proj_dir}/clusters/eks/kubeconfig_openfaas"
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

openwhisk() {
  config_file="openwhisk.yaml"

  if [ $remote = "true" ]
  then
    export KUBECONFIG="${proj_dir}/clusters/eks/kubeconfig_openwhisk"
    config_file="openwhisk-eks.yaml"
  fi

  if [ $delete = "false" ]
  then
    echo "Setting up OpenWhisk..."

    helm install metrics-server --namespace kube-system stable/metrics-server \
      --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}"

    kubectl label nodes --all openwhisk-role=invoker
    kubectl create namespace openwhisk

    git clone https://github.com/apache/openwhisk-deploy-kube.git
    cd openwhisk-deploy-kube
    helm install owdev ./helm/openwhisk -n openwhisk -f ../clusters/openwhisk/$config_file

    # Clean up
    cd ..
    rm -rf openwhisk-deploy-kube
  else
    echo "Deleting OpenWhisk..."
    helm uninstall owdev -n openwhisk
    kubectl delete ns openwhisk
    kubectl label nodes --all openwhisk-role-
    helm uninstall metrics-server -n kube-system
  fi
}

kubeless() {
  if [ $remote = "true" ]
  then
    export KUBECONFIG="${proj_dir}/clusters/eks/kubeconfig_kubeless"
  fi

  if [ $delete = "false" ]
  then
    echo "Setting up Kubeless..."

    helm install metrics-server --namespace kube-system stable/metrics-server \
      --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}"

    kubectl create ns kubeless
    kubectl create -f https://github.com/kubeless/kubeless/releases/download/v1.0.6/kubeless-v1.0.6.yaml
    helm install nginx-ingress stable/nginx-ingress --set rbac.create=true
  else
    echo "Deleting Kubeless..."
    helm uninstall nginx-ingress
    kubectl delete -f https://github.com/kubeless/kubeless/releases/download/v1.0.6/kubeless-v1.0.6.yaml
    kubectl delete ns kubeless
    helm uninstall metrics-server -n kube-system
  fi
}

fission() {
  if [ $remote = "true" ]
  then
    export KUBECONFIG="${proj_dir}/clusters/eks/kubeconfig_fission"
  fi

  if [ $delete = "false" ]
  then
    echo "Setting up Fission..."

    helm install metrics-server --namespace kube-system stable/metrics-server \
      --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}"

    kubectl create ns fission
    helm install fission -n fission \
      https://github.com/fission/fission/releases/download/1.8.0/fission-core-1.8.0.tgz
  else
    echo "Deleting Fission..."
    helm uninstall fission -n fission
    kubectl delete ns fission
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

unset KUBECONFIG

case $1 in
  "knative") knative ;;
  "openfaas") openfaas ;;
  "openwhisk") openwhisk ;;
  "kubeless") kubeless ;;
  "fission") fission ;;
  *) echo "Invalid platform" ;;
esac
