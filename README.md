# Evaluation of Emerging Serverless Platforms

## Setup

### EKS Clusters

_Skip if using the local Kubernetes cluster._

To be added

### Open-Source Serverless Platforms

Note: Add flag `-r` when running `setup.sh` for deploying to EKS. Terraform has to be run first.

**Knative**

```sh
# Set up Knative locally
./setup.sh knative

# Function deployment to be added

# Delete Knative from the cluster
./setup.sh knative -d
```

**OpenFaaS**

```sh
# Set up OpenFaaS locally
./setup.sh openfaas

# Log into OpenFaaS server when it's ready before deploying functions
OPENFAAS_URL="http://$(kubectl get svc -n openfaas gateway-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8080"
PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin --password-stdin

# Delete OpenFaaS from the cluster
./setup.sh openfaas -d
```
