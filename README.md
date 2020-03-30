# Evaluation of Emerging Serverless Platforms

## Setup

### EKS Clusters

_Skip if using the local Kubernetes cluster._

If you don't want to create clusters for all the included platforms, comment out the unwanted modules in `clusters/eks/main.tf`.

```sh
cd clusters/eks

terraform apply

# To remove a specific cluster (replace <cluster_name> with the name, e.g., knative)
terraform destroy -target=module.<cluster_name>

# Remove everything on AWS created by the Terraform config
terraform destroy

# Go back to the root project directory
cd ../..
```

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

# Function deployment to be added

# Delete OpenFaaS from the cluster
./setup.sh openfaas -d
```
