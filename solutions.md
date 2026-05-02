</details>

******

<details>
<summary>Exercise 1 & 2: Create Terraform project to spin up EKS cluster </summary>
 <br />

##### This project provisions an EKS cluster with the following configuration

:warning: Make sure to follow the instructions outlined in the README file to configure K8s storage correctly!

- **S3 bucket** as a storage for Terraform state
- K8s cluster with **3 nodes** and **1 fargate profile** for "my-app" namespace with **EBS CSI Driver add-on installed and correct node group permissions configured**
- **Mysql** chart with 3 replicas
- K8s version **1.28**
- AWS region for VPC, EKS and S3 bucket: **"eu-central-1**"

:warning: Make sure to change the region for your cluster in all relevant places!

:information_source: Check **README.md** file for the exact versions used in the projects for:
- _Terraform_
- _Terraform modules_
- _Terraform providers_

##### To execute the project
- set variables values in the **"dev.tfvars"** file
- set **"bucket name"** and **"bucket region"** values in the terraform configuration in the **"vpc.tf"** file
- `terraform init` - installs all the providers and modules used in the project
- `terraform apply` - executes the Terraform script

##### To access the cluster with kubectl, once it's configured
- `aws eks update-kubeconfig --name {cluster-name} --region {your-region}`

_ex: `aws eks update-kubeconfig --name my-cluster --region eu-central-1`_

:information_source: This will configure the kubeconfig file in the ~/.kube/ folder

##### To verify the cluster access
- `kubectl get nodes`
- `eksctl get fargateprofile --cluster my-cluster`

</details>

******

<details>
<summary>Exercise 3: CI/CD pipeline for Terraform project </summary>
 <br />

##### This project includes a Jenkinsfile for CI/CD pipeline

Values of the following environment variables need to be set inside jenkinsfile
- TF_VAR_env_prefix = "dev"
- TF_VAR_k8s_version = "1.29"
- TF_VAR_cluster_name = "my-cluster"
- TF_VAR_region = "eu-north-1

Values of the following environment variables need to be configured as Jenkins credentials
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
</details>