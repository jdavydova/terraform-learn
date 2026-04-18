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

  git checkout -b feature/deploy-to-ec2-default-component

# Terraform: user_data, Provisioners, and Modules

## Using External Scripts with user_data

Instead of embedding long scripts inside Terraform, you can reference a
file:

``` hcl
user_data = file("entry-script.sh")
user_data_replace_on_change = true
```

### Why use this?

-   Keeps Terraform code clean
-   Easier to manage complex scripts
-   Reusable scripts

------------------------------------------------------------------------

## Provisioners in Terraform

Provisioners execute scripts **after a resource is created**.

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

Copies files from local machine to EC2:

``` hcl
provisioner "file" {
  source      = "entry-script.sh"
  destination = "/home/ec2-user/entry-script-on-ec2.sh"
}
```

------------------------------------------------------------------------

### Remote Exec Provisioner

Runs commands on the remote server:

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

Runs commands locally (on your machine):

``` hcl
provisioner "local-exec" {
  command = "echo ${self.public_ip} > output.txt"
}
```

------------------------------------------------------------------------

## Key Differences

  Feature       Description
  ------------- ------------------------------------
  user_data     Runs at instance startup (via AWS)
  remote-exec   Runs via SSH after creation
  file          Copies files to resource
  local-exec    Runs locally

------------------------------------------------------------------------

## ⚠️ Why Provisioners Are NOT Recommended

Terraform discourages using provisioners because:

-   Break idempotency
-   Terraform cannot track what scripts do
-   No guarantee commands succeed
-   Breaks desired-state model

### Best Practice:

Use `user_data` whenever possible

------------------------------------------------------------------------

## Modules in Terraform

Modules help organize and reuse infrastructure code.

### Example: EC2 Module (webserver)

Project structure:

    modules/
      webserver/
        main.tf
        variables.tf
        outputs.tf
        providers.tf

------------------------------------------------------------------------

### Create Module Directory

``` bash
mkdir -p modules/webserver
cd modules/webserver
touch main.tf variables.tf outputs.tf providers.tf
```

------------------------------------------------------------------------

## Module Outputs

Outputs allow child modules to expose values:

``` hcl
output "instance_ip" {
  value = aws_instance.app_server.public_ip
}
```

### Access from Parent Module:

``` hcl
module.webserver.instance_ip
```

------------------------------------------------------------------------

## Apply Configuration

``` bash
terraform init
terraform apply -auto-approve
```

------------------------------------------------------------------------

## Summary

-   Use user_data for bootstrapping
-   Avoid provisioners unless necessary
-   Use modules for reusable infrastructure
-   Keep Terraform declarative and predictable


