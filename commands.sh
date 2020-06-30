# This file contains commands that were used during the development and experiments.
# This is not a script. Don't run it.

########################################################################################
########################################################################################
########################################################################################

# HPA (for OpenFaaS, Kubeless, Fission)
# ===
# Prerequisites:
#   - Helm
helm repo add stable https://kubernetes-charts.storage.googleapis.com
# helm install metrics-server --namespace kube-system stable/metrics-server
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" # For testing
# If not working
# helm uninstall metrics-server -n kube-system
helm install metrics-server --namespace kube-system stable/metrics-server \
  --set args="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP\,ExternalIP\,Hostname}"

# kubectl apply -f secrets/metrics-server/deploy/kubernetes

########################################################################################
########################################################################################
########################################################################################

# Knative
# =======
# https://knative.dev/docs/install/any-kubernetes-cluster
# https://knative.dev/docs/install/install-kn (Knative CLI, optional)
# https://serverless.com/framework/docs/providers/knative/guide/quick-start
# Prerequisites:
#   - Helm
#   - Istio
# Steps:
#   - Install according to the instructions
#   - Add cluster-local-gateway for Istio as well
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.13.0/serving-crds.yaml
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.13.0/serving-core.yaml

kubectl apply -f clusters/knative/istio-crds.yaml
kubectl apply -f clusters/knative/istio-minimal.yaml
kubectl apply -f clusters/knative/istio-knative-extras.yaml

kubectl apply --filename https://github.com/knative/serving/releases/download/v0.13.0/serving-istio.yaml

# kubectl patch configmap/config-domain \
#   --namespace knative-serving \
#   --type merge \
#   --patch '{"data":{"nropatas.com":""}}'

# kubectl edit cm config-domain --namespace knative-serving

# If required to configure autoscaling
kubectl edit cm config-autoscaler -n knative-serving

# Serverless Framework (not working)
# ====================
# Prerequisites:
#   - Node.js
# serverless create --template knative-docker --path functions/knative

# export DOCKER_HUB_USERNAME=nropatas \
#   DOCKER_HUB_PASSWORD="SamSam33."

# serverless deploy
# serverless remove

# Without Serverless Framework
docker build -t nropatas/knative-simple .
docker push nropatas/knative-simple

kubectl apply -f service.yml
kubectl get ksvc
kn service list

# curl -H "Host: knative-simple.default.nropatas.com" http://localhost
curl -H "Host: knative-simple.default.example.com" http://localhost
curl -H "Host: knative-simple.default.example.com" http://aed18eb1547d24350a97621f5ecb7253-2043097814.eu-central-1.elb.amazonaws.com

########################################################################################
########################################################################################

# OpenFaaS
# ========
# https://github.com/openfaas/faas-netes
# https://github.com/openfaas/faas-netes/blob/master/chart/openfaas/README.md
# Prerequisites:
#   - Helm
brew install faas-cli

kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

helm template \
  openfaas chart/openfaas/ \
  --namespace openfaas \
  --set generateBasicAuth=true \
  --set functionNamespace=openfaas-fn \
  --set rbac=false \
  --set serviceType=LoadBalancer > openfaas.yaml

kubectl apply -f openfaas.yaml
kubectl apply -f openfaas-rbac.yaml

kubectl get svc -n openfaas gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
OPENFAAS_URL="http://$(kubectl get svc -n openfaas gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8080"
# OPENFAAS_URL=http://localhost:8080
PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin --password-stdin

# Deploy a function
faas-cli template pull
faas-cli new openfaas --lang node12
# Update openfaas.yml, handler, and package.json
faas-cli up -f openfaas.yml
faas-cli up -g $OPENFAAS_URL -f openfaas.yml
faas-cli list

# For scaling with CPU usage (max is required)
kubectl autoscale deployment -n openfaas-fn \
  openfaas-simple \
  --cpu-percent=50 \
  --min=1 \
  --max=10

curl http://localhost:8080/function/openfaas-simple

########################################################################################
########################################################################################

# OpenWhisk
# =========
# https://github.com/apache/openwhisk-deploy-kube
# https://serverless.com/framework/docs/providers/openwhisk/guide/quick-start
# https://github.com/apache/openwhisk/blob/master/docs/apigateway.md
# Prerequisites:
#   - Helm
#   - openwhisk-cli (wsk)
# Server cert for EKS
openssl genrsa -out openwhisk-server-key.pem 2048
openssl req -new \
  -key openwhisk-server-key.pem \
  -nodes \
  -out openwhisk-server-request.csr
openssl x509 -req \
  -in openwhisk-server-request.csr \
  -signkey openwhisk-server-key.pem \
  -out openwhisk-server-cert.pem \
  -days 365

aws iam upload-server-certificate --server-certificate-name ow-self-signed --certificate-body file://clusters/openwhisk/openwhisk-server-cert.pem --private-key file://clusters/openwhisk/openwhisk-server-key.pem
aws iam list-server-certificates

kubectl label nodes --all openwhisk-role=invoker
kubectl create namespace openwhisk

git clone https://github.com/apache/openwhisk-deploy-kube.git
cd openwhisk-deploy-kube
helm install owdev ./helm/openwhisk -n openwhisk -f ../../clusters/openwhisk/openwhisk.yaml

kubectl get svc -n openwhisk owdev-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Set up openwhisk-cli (local)
wsk property set --apihost localhost:31001
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
# EKS
wsk property set --apihost "$(kubectl get svc -n openwhisk owdev-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):443"

echo "APIGW_ACCESS_TOKEN=token" >> ~/.wskprops

# Deploy a service
npm install -g serverless-openwhisk
serverless create --template openwhisk-nodejs --path functions/openwhisk

# export OW_AUTH=23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
# export OW_APIHOST=localhost:31001
# export OW_APIHOST="$(kubectl get svc -n openwhisk owdev-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):443"

serverless deploy -v
curl -k https://localhost:31001/api/23bc46b1-71f6-4ed5-8c54-816aa4f8c502/openwhisk-simple

wsk action get -i --url openwhisk-dev-openwhisk-simple

sls remove -v
helm uninstall owdev -n openwhisk

########################################################################################
########################################################################################

# Kubeless
# ========
# https://kubeless.io/docs/quick-start
# https://serverless.com/framework/docs/providers/kubeless/guide/quick-start
# https://kubeless.io/docs/http-triggers
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md
# Prerequisites:
#   - Kubeless CLI (kubeless)
#   - Serverless Framework
kubectl create ns kubeless
kubectl create -f https://github.com/kubeless/kubeless/releases/download/v1.0.6/kubeless-v1.0.6.yaml

# Nginx Ingress
# kubectl create ns ingress-nginx
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml
# or
helm install nginx-ingress stable/nginx-ingress --set rbac.create=true

# sls create --template kubeless-nodejs
# npm install -g serverless-kubeless

# sls deploy -v # Not working on EKS
# kubeless function update kubeless-simple --cpu 10m
# or
kubeless function deploy kubeless-simple -r nodejs12 \
  -f handler.js \
  --handler handler.simple \
  --cpu 10m \
  --memory 128Mi

# Expose the function
# kubeless trigger http create kubeless-simple --function-name kubeless-simple
kubeless trigger http create kubeless-simple --function-name kubeless-simple --hostname example.com --path kubeless-simple

# Set auto-scaling (CPU)
kubeless autoscale create kubeless-simple --metric=cpu --min=1 --max=10 --value=50
kubectl get hpa

# Set auto-scaling (QPS)
# kubectl create ns prometheus
# helm install prometheus-operator stable/prometheus-operator -n prometheus
# helm install prometheus-adapter stable/prometheus-adapter -n prometheus

kubectl get functions
kubeless function ls
kubeless function call kubeless-simple
kubectl get ingress
curl -H "Host: kubeless-simple.kubernetes.docker.internal.nip.io" localhost
# EKS
curl -H "Host: kubeless-simple.example.com" $(kubectl get svc nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# kubeless autoscale delete kubeless-simple
# kubeless trigger http delete kubeless-simple
# sls remove -v
# or
kubeless function delete kubeless-simple # Delete everything

# Remove Prometheus
helm uninstall prometheus-adapter -n prometheus

helm uninstall prometheus-operator -n prometheus
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com

kubectl delete ns prometheus

########################################################################################
########################################################################################

# Fission
# =======
# https://docs.fission.io/docs/installation
# Prerequisites:
#   - Helm
#   - Fission CLI
kubectl create ns fission
helm install fission -n fission \
  https://github.com/fission/fission/releases/download/1.8.0/fission-core-1.8.0.tgz

fission env create --name node --image fission/node-env
fission fn create --name fission-simple --env node --code simple.js
fission fn create --name fission-simple --env node --code simple.js \
  --executortype newdeploy --mincpu=1 --maxcpu=100 --minmemory=1 --maxmemory=128 --minscale=1 --maxscale=10 --targetcpu=80
fission route create --method GET --url /fission-simple --function fission-simple --name fission-simple

kubectl get function
fission function test --name fission-simple
curl localhost/fission-simple
# EKS
curl $(kubectl get svc -n fission router -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/fission-simple

kubectl get deploy -n fission-function -l 'functionName=fission-simple' -o jsonpath='{.items[0].status.conditions[0].status}'

# Delete httptrigger, fn, pkg, env
fission httptrigger delete --name fission-simple
fission function delete --name fission-simple
# fission pkg list
# fission pkg delete --name <name>
fission pkg delete --orphan
fission env delete --name node

helm uninstall fission -n fission
kubectl delete ns fission

########################################################################################
########################################################################################

# AWS Lambda
# ==========
# Prerequisites:
#   - node10 (nvm)
#   - sls
#   - aws-cli
aws configure
serverless create --template aws-nodejs --path functions/aws
sls deploy -v

curl https://929ehf03e0.execute-api.us-east-1.amazonaws.com/dev/aws-simple

sls remove

########################################################################################
########################################################################################

# Azure
# =====
# https://serverless.com/framework/docs/providers/azure/guide/quick-start
# Prerequisites:
#   - Azure CLI (logged in)
#   - sls
brew install azure-cli
az login
az account list
az account set -s <id>
az ad sp create-for-rbac --name serverless

export AZURE_SUBSCRIPTION_ID="" \
  AZURE_TENANT_ID="" \
  AZURE_CLIENT_ID="http://serverless" \
  AZURE_CLIENT_SECRET=""

sls create -t azure-nodejs

nvm use 10
npm i azure-functions-core-tools -g

sls offline
# npm start
sls offline cleanup

sls deploy -v

sls func add -n {functionName}
sls func remove -n {functionName}

sls remove -v

########################################################################################
########################################################################################
########################################################################################

# AWS EKS
# =======
# https://learn.hashicorp.com/terraform/getting-started/intro
# https://learn.hashicorp.com/terraform/aws/eks-intro
# https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
# Prerequisites:
#   - Terraform CLI
#   - AWS CLI (logged in)
#   - aws-iam-authenticator
terraform init
terraform apply

export KUBECONFIG=kubeconfig_knative

terraform destroy -target=module.knative
terraform destroy

########################################################################################
########################################################################################

# GKE
# ===
# https://www.padok.fr/en/blog/kubernetes-google-cloud-terraform-cluster
# https://github.com/terraform-google-modules/terraform-google-kubernetes-engine
# Prerequisites:
#   - gcloud

########################################################################################
########################################################################################
########################################################################################

# FaaSTest
# ========
export AWS_ACCESS_KEY_ID="" \
  AWS_SECRET_ACCESS_KEY=""

./faasbenchmark run aws BurstLvl1
./faasbenchmark run knative BurstLvl1
./faasbenchmark run openfaas BurstLvl1
./faasbenchmark run openwhisk BurstLvl1
./faasbenchmark run kubeless BurstLvl1
./faasbenchmark run fission BurstLvl1

./runtest.sh "./faasbenchmark run knative BurstLvl1 -r results/BurstLvl1/knative" 10 1m
./runtest.sh "./faasbenchmark run fission ConcurrentIncreasingLoadLvl1 -r results/ConcurrentIncreasingLoadLvl1/fission" 10 1m
./runtest.sh "./faasbenchmark run azure IncreasingCPULoadLvl1 -r results/IncreasingCPULoadLvl1/azure" 10 1m
./runtest.sh "./faasbenchmark run azure IncreasingMemLoadLvl1 -r results/IncreasingMemLoadLvl1/azure" 10 1m

########################################################################################
########################################################################################

# Before running the container
# 1. Run terraform
# 2. Copy kubeconfigs
cp kubeconfig_* ../../benchmarks/faastest/kubeconfigs
# 3. Run setup.sh
./deploy.sh
# 4. Copy ingress urls to provider/providers.json
kubectl get svc -A
# 5. Build images, push images, and correct docker hub address (Knative, OpenFaaS)
docker build -t nropatas/faastest-sleep-node13 .
docker push nropatas/faastest-sleep-node13

faas-cli build -f openfaas.yml
faas-cli push -f openfaas.yml
# 6. Build faasbenchmark image
docker build -t faasbenchmark .
docker build -t nropatas/faasbenchmark .

########################################################################################

docker pull nropatas/faasbenchmark

docker run -it faasbenchmark /bin/bash
docker run -it --ulimit nofile=100000:100000 --name one nropatas/faasbenchmark /bin/bash
# After running the container, before running tests
# 1. Export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY (Knative, OpenFaaS, OpenWhisk, Kubeless, Fission)
# 2. Log in as admin (OpenFaaS)
OPENFAAS_URL="http://$(kubectl get svc -n openfaas gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' --kubeconfig /app/kubeconfigs/kubeconfig_openfaas):8080"
PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" --kubeconfig /app/kubeconfigs/kubeconfig_openfaas | base64 --decode)
echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin --password-stdin
# 3. Set wsk credentials (OpenWhisk)
wsk property set --apihost "$(kubectl get svc -n openwhisk owdev-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' --kubeconfig /app/kubeconfigs/kubeconfig_openwhisk):443"
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
# 4. Export KUBECONFIG (Kubeless, Fission)
export KUBECONFIG=/app/kubeconfigs/kubeconfig_kubeless
export KUBECONFIG=/app/kubeconfigs/kubeconfig_fission

########################################################################################
########################################################################################

# Run faasbenchmark on AWS EC2
# https://medium.com/@hmalgewatta/setting-up-an-aws-ec2-instance-with-ssh-access-using-terraform-c336c812322f

# 1. Create a key-pair on EC2 console and set the correct name in variables.tf

# Run faasbenchmark on Azure
# https://github.com/terraform-providers/terraform-provider-azurerm/tree/master/examples/virtual-machines/linux
# https://github.com/paulbouwer/terraform-azure-quickstarts-samples/tree/master/docker-simple-on-ubuntu-managed-disks

ssh adminuser@<ip>

########################################################################################

ssh ec2-user@<ip>
ssh adminuser@<ip>

docker logs -f --since 2020-05-16T17:53:00 one | grep "status:"

docker cp <id>:/app/results $(pwd)

scp -r ec2-user@<ip>:/home/ec2-user/results
scp -r adminuser@<ip>:/home/adminuser/results

# Copy a file through SSH
scp ec2-user@<ip_address>:<filepath> /local/dir
# Copy a dir through SSH
scp -r ec2-user@<ip_address>:<dirpath> /local/dir

# Copy file/dir from docker container to host
docker cp <containerId>:/file/path/within/container /host/path/target

# Save logs
docker inspect --format='{{.LogPath}}' <container>

# Remove empty dirs
find . -type d -empty -print
find . -type d -empty -delete

find results -type d -empty -print
