# Evaluation of Emerging Serverless Platforms

## Setup

### Prerequisites

* **Helm**

    After installing Helm CLI, run this command.

    ```sh
    helm repo add stable https://kubernetes-charts.storage.googleapis.com
    ```

To be added

### EKS Clusters

_Skip if using the local Kubernetes cluster._

Before running the following commands, set up your AWS credentials by running `aws configure`.

If you don't want to create clusters for all the included platforms, comment out the unwanted modules in `clusters/eks/main.tf`.

```sh
cd clusters/eks

terraform init
terraform apply

# To remove a specific cluster (replace <cluster_name> with the name, e.g., knative)
terraform destroy -target=module.<cluster_name>

# Remove everything on AWS created by the Terraform config
terraform destroy

# Go back to the project root directory
cd ../..
```

### Open-Source Serverless Platforms

Note: Add flag `-r` when running `setup.sh` for deploying to EKS or removing the stacks from EKS. Terraform has to be run first.

Run this if you are working on your local cluster.

```sh
unset KUBECONFIG
```

**Knative**

```sh
# Run this if you are using EKS
export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_knative"

# Set up Knative locally
./setup.sh knative

# Function deployment to be added

# Delete Knative from the cluster
./setup.sh knative -d
```

**OpenFaaS**

```sh
# Run this if you are using EKS
export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_openfaas"

# Set up OpenFaaS locally
./setup.sh openfaas

# Log into OpenFaaS server when it's ready before deploying functions
OPENFAAS_URL="http://$(kubectl get svc -n openfaas gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8080"
PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin --password-stdin

# Function deployment to be added

# Delete OpenFaaS from the cluster
./setup.sh openfaas -d
```

**OpenWhisk**

```sh
# Generate a self-signed server certificate (only for EKS)
openssl genrsa -out clusters/openwhisk/openwhisk-server-key.pem 2048
openssl req -new \
  -key clusters/openwhisk/openwhisk-server-key.pem \
  -nodes \
  -out clusters/openwhisk/openwhisk-server-request.csr
openssl x509 -req \
  -in clusters/openwhisk/openwhisk-server-request.csr \
  -signkey clusters/openwhisk/openwhisk-server-key.pem \
  -out clusters/openwhisk/openwhisk-server-cert.pem \
  -days 365

# Run this command, copy ARN, and paste it in `clusters/openwhisk/openwhisk-eks.yaml`
aws iam upload-server-certificate --server-certificate-name ow-self-signed --certificate-body file://clusters/openwhisk/openwhisk-server-cert.pem --private-key file://clusters/openwhisk/openwhisk-server-key.pem

# Run this if you are using EKS
export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_openwhisk"

# Set up OpenWhisk locally
./setup.sh openwhisk

# Wait until everything is ready and configure wsk (CLI)
# For local K8S cluster
wsk property set --apihost localhost:31001
# For EKS cluster
wsk property set --apihost "$(kubectl get svc -n openwhisk owdev-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):443"
wsk property set --auth 23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
echo "APIGW_ACCESS_TOKEN=token" >> ~/.wskprops

# Function deployment to be added

# Delete OpenWhisk from the cluster
./setup.sh openwhisk -d
```

**Kubeless**

```sh
# Run this if you are using EKS
export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_kubeless"

# Set up Kubeless locally
./setup.sh kubeless

# Function deployment to be added

# Delete Kubeless from the cluster
./setup.sh kubeless -d
```

**Fission**

```sh
# Run this if you are using EKS
export KUBECONFIG="$(pwd)/clusters/eks/kubeconfig_fission"

# Set up Fission locally
./setup.sh fission

# Function deployment to be added

# Delete Fission from the cluster
./setup.sh fission -d
```
