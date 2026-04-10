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
