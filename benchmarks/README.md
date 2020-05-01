# Serverless Platform Benchmarking

## FaaSTest by Nuweba

If you want to run FaaSTest on Azure Functions, do the followings.

1. Create an SSH key pair.
2. Correct the path to the public key (`public_key_path`) in `clusters/azure-vm/variables.tf`.
3. Run these commands.

```sh
az login

cd ../clusters/azure-vm
terraform init
terraform apply

ssh ec2-user@<ip_address>
```

To run FaaSTest on AWS Lambda and other open-source platforms, follow these steps.

1. Create a key pair on EC2 Console.
2. Correct the key pair name (`key_pair_name`) and path to the private key (`private_key_path`) in `clusters/ec2/variables.tf`.
3. Run these commands.

```sh
# Set up AWS credentials
aws configure

cd ../clusters/ec2
terraform init
terraform apply

ssh adminuser@<ip_address>
```

Note: Before connecting to the instance through SSH, make sure to add the private keys to `ssh-agent` (`ssh-add`).

Remove all resources by running `terraform destroy` in the corresponding directory.
