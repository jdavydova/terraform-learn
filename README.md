# 🚀 Infrastructure as Code (IaC) with Terraform (AWS)

This README provides a step-by-step guide to setting up Terraform and provisioning AWS infrastructure.

---

## 📦 Install Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

---

## 📁 Project Setup

```bash
mkdir terraform
cd terraform
```

Create main file:

```bash
touch main.tf
```

Install Terraform extension in **Visual Studio Code**.

---

## ⚙️ Configure Providers

### providers.tf

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
  }
}
```

---

## 🔐 Configure AWS Provider (⚠️ Not Recommended Way)

```hcl
provider "aws" {
  region     = "eu-north-1"
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_KEY"
}
```

> ⚠️ Do NOT hardcode credentials in production. Use environment variables or AWS CLI.

---

## ▶️ Initialize Terraform

```bash
terraform init
```

---

## ☁️ Create AWS Resources

### Example: Use existing VPC and create subnet

```hcl
data "aws_vpc" "existing_vpc" {
  default = true
}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = "172.31.48.0/20"
  availability_zone = "eu-north-1a"
}
```

---

## 🚀 Apply Configuration

```bash
terraform apply
```

Auto approve:

```bash
terraform apply -auto-approve
```

---

## ❌ Destroy Resources

```bash
terraform destroy
```

Destroy specific resource:

```bash
terraform destroy -target aws_subnet.dev-subnet-2
```

---

## 📊 Terraform State & Output

```hcl
output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id
}
```

---

## 🔄 Variables

### Define variable

```hcl
variable "subnet_cidr_block" {
  description = "subnet cidr block"
  type        = string
  default     = "10.0.10.0/24"
}
```

### Assign variable

```bash
terraform apply -var "subnet_cidr_block=10.0.30.0/24"
```

### terraform.tfvars

```hcl
subnet_cidr_block = "10.0.40.0/24"
```

### Use variable file

```bash
terraform apply -var-file terraform-dev.tfvars
```

---

## 🌍 Environment Variables (Recommended)

```bash
export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY
```

Check:

```bash
env | grep AWS
```

Alternative:

```bash
aws configure
```

### Terraform variable via env

```bash
export TF_VAR_avail_zone="eu-north-1"
```

---

## 📂 Git Setup

Create `.gitignore` and connect to remote repository.

---

## 🏗️ Infrastructure to Provision

- Custom VPC
- Subnet
- Route Table
- Internet Gateway
- EC2 Instance
- Docker (Nginx)
- Security Group

---

## 🌐 Networking Example

### Route Table

```hcl
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}
```

---

### Internet Gateway

```hcl
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
```

---

### Route Table Association

```hcl
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet.id
  route_table_id = aws_route_table.myapp-route-table.id
}
```

---

## 🧠 Best Practices

- Do NOT hardcode secrets
- Use environment variables or IAM roles
- Keep Terraform code in Git
- Create infrastructure from scratch

---

## 🔑 Summary

Terraform allows you to:

- Define infrastructure as code
- Provision AWS resources automatically
- Manage environments consistently
- Version control infrastructure

---

## 📚 Useful Links

https://registry.terraform.io/providers/hashicorp/aws/latest

## Main Route Table

This configuration updates the default route table of the VPC to allow
internet access.

``` hcl
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-main-rtb"
  }
}
```

### Explanation

-   Uses the **default route table** created with the VPC.
-   Adds a route to the **Internet Gateway**.
-   Allows all outbound traffic to the internet.

------------------------------------------------------------------------

## Security Group

Defines firewall rules for your application.

``` hcl
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids  = []
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}
```

### Explanation

-   **Port 22 (SSH)**: Access allowed only from your IP (`var.my_ip`)
-   **Port 8080**: Open to the public (for your application)
-   **Egress**: Allows all outbound traffic to anywhere

------------------------------------------------------------------------

# Automate EC2 Provisioning with Terraform

## Fetch Latest Amazon Linux AMI

``` hcl
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest_amazon_linux.id
}
```

------------------------------------------------------------------------

## Create EC2 Instance

``` hcl
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default_sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true
  key_name                    = "server-key"
}
```

------------------------------------------------------------------------

## SSH Key Setup

1.  Create key pair:

``` hcl
resource "aws_key_pair" "ssh_key" {
  key_name   = "server-key"
  public_key = var.my_public_key
}
```

2.  Save private key locally:

```{=html}
<!-- -->
```
    ~/.ssh/server_key_pair.pem

3.  Set correct permissions:

``` bash
chmod 400 ~/.ssh/server_key_pair.pem
```

> AWS will reject SSH if permissions are too open.

------------------------------------------------------------------------

## Connect via SSH

``` bash
ssh -i ~/.ssh/server_key_pair.pem ec2-user@<public-ip>
```

------------------------------------------------------------------------

## Automate Instance Setup with user_data

``` hcl
user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
docker run -p 8080:80 nginx
EOF

user_data_replace_on_change = true
```

<img width="1132" height="525" alt="Screenshot 2026-04-16 at 9 43 25 AM" src="https://github.com/user-attachments/assets/32fc0b1c-9e32-43dd-98e2-23e1822f1def" />

## Using External Scripts with user_data

For longer or more complex scripts, instead of embedding them directly
in Terraform, you can reference a file:

``` hcl
user_data = file("entry-script.sh")
```

### Benefits

-   Cleaner Terraform configuration
-   Easier to manage scripts
-   Reusable logic

------------------------------------------------------------------------

## Provisioners in Terraform

Provisioners execute scripts on resources **after they are created**.

### SSH Connection

``` hcl
connection {
  type        = "ssh"
  host        = self.public_ip
  user        = "ec2-user"
  private_key = file(var.private_key_location)
}
```

------------------------------------------------------------------------

### File Provisioner

Copies files from local machine to the resource:

``` hcl
provisioner "file" {
  source      = "entry-script.sh"
  destination = "/home/ec2-user/entry-script-on-ec2.sh"
}
```

------------------------------------------------------------------------

### Remote Exec Provisioner

Executes commands on the remote server:

``` hcl
provisioner "remote-exec" {
  inline = [
    "export ENV=dev",
    "mkdir newer"
  ]
}
```

------------------------------------------------------------------------

### Local Exec Provisioner

Runs commands locally:

``` hcl
provisioner "local-exec" {
  command = "echo ${self.public_ip} > output.txt"
}
```

------------------------------------------------------------------------

## Key Differences

  Feature       Description
  ------------- ----------------------------------
  user_data     Runs at instance startup via AWS
  remote-exec   Runs via SSH after creation
  file          Copies files to remote resource
  local-exec    Runs locally

------------------------------------------------------------------------

## ⚠️ Why Provisioners Are Not Recommended

Terraform discourages provisioners because:

-   Break idempotency
-   Terraform cannot track script execution
-   No guarantee scripts run successfully
-   Breaks desired state model

### Best Practice

Use `user_data` whenever possible.

------------------------------------------------------------------------

## Modules in Terraform

Modules allow reusable infrastructure components.

### Example: EC2 Module (webserver)

Project structure:

    modules/
      webserver/
        main.tf
        variables.tf
        outputs.tf
        providers.tf

------------------------------------------------------------------------

### Create Module

``` bash
mkdir modules
cd modules
mkdir webserver
cd webserver

touch main.tf variables.tf outputs.tf providers.tf
```

------------------------------------------------------------------------

## Module Outputs

Outputs expose values from child modules:

``` hcl
output "instance_ip" {
  value = aws_instance.app_server.public_ip
}
```

### Access from parent module:

``` hcl
module.webserver.instance_ip
```

------------------------------------------------------------------------

## Apply Terraform

``` bash
terraform init
terraform apply -auto-approve
```

------------------------------------------------------------------------

<img width="511" height="234" alt="Screenshot 2026-04-18 at 5 19 06 PM" src="https://github.com/user-attachments/assets/28c66879-05fa-49c0-976d-5bf366e8f198" />

# Automate Provisioning EKS Cluster with Terraform

## Overview

This guide explains how to provision an AWS EKS cluster using Terraform
and the required infrastructure components.

------------------------------------------------------------------------

## EKS Architecture Basics

An EKS cluster consists of:

-   **Control Plane (managed by AWS)**
    -   Highly available
    -   Managed by AWS (no need to configure manually)
-   **Worker Nodes**
    -   EC2 instances or Fargate
    -   Must be connected to the control plane

------------------------------------------------------------------------

## Git Workflow

``` bash
git checkout -b feature/eks
```

------------------------------------------------------------------------

## VPC Requirements for EKS

EKS requires: - Proper VPC configuration - Public and private subnets -
Route tables - Internet access (via NAT)

Best practice: - At least **1 public + 1 private subnet per Availability
Zone**

------------------------------------------------------------------------

## Terraform vs CloudFormation

-   CloudFormation = AWS-specific
-   Terraform = multi-cloud (used here)

------------------------------------------------------------------------

## VPC Module (vpc.tf)

``` hcl
module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "myapp-vpc"
  cidr = var.vpc_cidr_block

  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
}
```

------------------------------------------------------------------------

## 1. Provider Configuration

``` hcl
provider "aws" {
  region = "eu-north-1"
}
```

Defines AWS region (Stockholm).

------------------------------------------------------------------------

## 2. Variables

``` hcl
variable "vpc_cidr_block" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}
```

Used to pass: - VPC CIDR - Private subnets - Public subnets

Example:

``` hcl
vpc_cidr_block = "10.0.0.0/16"
```

------------------------------------------------------------------------

## 3. Availability Zones (Data Source)

``` hcl
data "aws_availability_zones" "azs" {}
```

Fetches available AZs dynamically.

Example result:

    ["eu-north-1a", "eu-north-1b", "eu-north-1c"]

------------------------------------------------------------------------

## 4. VPC Module Explained

``` hcl
module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"
```

Uses a pre-built module that creates: - VPC - Subnets - Route tables -
NAT Gateway - Networking components

------------------------------------------------------------------------

## 5. VPC Configuration

``` hcl
name = "myapp-vpc"
cidr = var.vpc_cidr_block
```

Creates VPC with defined CIDR range.

------------------------------------------------------------------------

## 6. Subnets

``` hcl
private_subnets = var.private_subnet_cidr_blocks
public_subnets  = var.public_subnet_cidr_blocks
azs             = data.aws_availability_zones.azs.names
```

-   Public subnets → internet-facing (load balancers)
-   Private subnets → internal workloads (apps, DB)

AZ distribution ensures high availability.

------------------------------------------------------------------------

## 7. NAT Gateway

``` hcl
enable_nat_gateway = true
single_nat_gateway = true
```

Allows private instances to access the internet.

-   `true` → enables outbound internet
-   `single_nat_gateway` → cheaper but less HA

------------------------------------------------------------------------

## 8. DNS Support

``` hcl
enable_dns_hostnames = true
```

Enables DNS hostnames for EC2 instances.

------------------------------------------------------------------------

## 9. Kubernetes (EKS) Tags

### Cluster Tag

``` hcl
tags = {
  "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
}
```

Marks VPC for EKS usage.

------------------------------------------------------------------------

### Public Subnet Tags

``` hcl
public_subnet_tags = {
  "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  "kubernetes.io/role/elb" = "1"
}
```

Allows: - Internet-facing Load Balancers

------------------------------------------------------------------------

### Private Subnet Tags

``` hcl
private_subnet_tags = {
  "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  "kubernetes.io/role/internal-elb" = "1"
}
```

Allows: - Internal Load Balancers

------------------------------------------------------------------------

## Summary

This Terraform setup creates:

-   VPC
-   Public & Private subnets
-   Availability zone distribution
-   NAT Gateway
-   DNS configuration
-   Kubernetes-ready infrastructure

------------------------------------------------------------------------

## Next Steps

``` bash
terraform init
terraform plan
terraform apply
```

------------------------------------------------------------------------

## Key DevOps Concepts

-   Infrastructure as Code (Terraform)
-   High Availability (multi-AZ)
-   Kubernetes networking requirements
-   AWS managed services (EKS)


<img width="498" height="293" alt="Screenshot 2026-04-22 at 11 05 57 AM" src="https://github.com/user-attachments/assets/c366f542-8058-4c8f-b096-f28e261c3a5d" />



<img width="989" height="489" alt="Screenshot 2026-04-22 at 11 32 59 AM" src="https://github.com/user-attachments/assets/8582ebed-6c7e-49f8-a49c-eea1684aa022" />


<img width="398" height="251" alt="Screenshot 2026-04-24 at 10 46 14 AM" src="https://github.com/user-attachments/assets/136b3c70-4f71-4c6d-bb0c-5ed2caffcd05" />


