# Terraform Complete Learning Guide - End to End

---

## My Learning Journey — Pi Cluster Practice Log

> Branch: `learn/terraform-journey` | Cluster: Pi k3s | State: MinIO (`terraform-state` bucket)
> All live examples: [study/k8s/learning/](study/k8s/learning/)

| Phase | Topic | Directory | Status | Key Command Run |
|-------|-------|-----------|--------|-----------------|
| 1 | count vs for_each | [01-count-foreach/](study/k8s/learning/) | ✅ Done | `kubectl get pods -n terraform-learning` |
| 2 | Variables deep dive | [02-variables/](study/k8s/learning/02-variables/) | 🔜 Next | — |
| 3 | Locals | [03-locals/](study/k8s/learning/03-locals/) | ⏳ Pending | — |
| 4 | Data Sources | [04-datasources/](study/k8s/learning/04-datasources/) | ⏳ Pending | — |
| 5 | Lifecycle rules | [05-lifecycle/](study/k8s/learning/05-lifecycle/) | ⏳ Pending | — |
| 6 | Workspaces | [06-workspaces/](study/k8s/learning/06-workspaces/) | ⏳ Pending | — |
| 7 | Functions & expressions | [07-functions/](study/k8s/learning/07-functions/) | ⏳ Pending | — |

### What I Learned

**Phase 1 — count vs for_each**
- `count` uses an index (0,1,2) — removing middle item shifts indexes and recreates resources
- `for_each` uses a key ("web","api") — removing a key only destroys that one resource
- `count = 0 or 1` is the standard toggle pattern for optional resources
- Terraform is **declarative** — it reconciles desired vs actual state (manually deleted pod gets recreated)
- Remote state lives in MinIO at `s3://terraform-state/learning/count-foreach/terraform.tfstate`
- Cloudflare Tunnel breaks SigV4 because it drops `Content-Length` header — use NodePort IP for Terraform backends

---

## Table of Contents
1. [Introduction to Terraform](#introduction-to-terraform)
2. [Installation and Setup](#installation-and-setup)
3. [Core Concepts](#core-concepts)
4. [Configuration Language (HCL)](#configuration-language-hcl)
5. [Providers](#providers)
6. [Resources](#resources)
7. [Variables and Outputs](#variables-and-outputs)
8. [Data Sources](#data-sources)
9. [State Management](#state-management)
10. [Modules](#modules)
11. [Provisioners](#provisioners)
12. [Backends](#backends)
13. [Workspaces](#workspaces)
14. [Functions and Expressions](#functions-and-expressions)
15. [Terraform Commands](#terraform-commands)
16. [Best Practices](#best-practices)
17. [Advanced Topics](#advanced-topics)
18. [Real-World Examples](#real-world-examples)
19. [Troubleshooting](#troubleshooting)
20. [CI/CD Integration](#cicd-integration)

---

## Introduction to Terraform

### What is Terraform?
Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp. It allows you to define and provision infrastructure using a declarative configuration language.

### Key Features
- **Infrastructure as Code**: Define infrastructure in configuration files
- **Execution Plans**: Preview changes before applying
- **Resource Graph**: Understands dependencies between resources
- **Change Automation**: Applies changes to reach desired state
- **Multi-Cloud**: Works with AWS, Azure, GCP, Kubernetes, and 1000+ providers

### Why Use Terraform?
- Version control for infrastructure
- Reproducible environments
- Collaboration and reusability
- Automated provisioning
- Cost optimization through resource management

---

## Installation and Setup

### Installing Terraform

#### Linux
```bash
# Using apt (Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Using binary
wget https://releases.hashicorp.com/terraform/1.8.0/terraform_1.8.0_linux_amd64.zip
unzip terraform_1.8.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### macOS
```bash
# Using Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version
```

#### Windows
```powershell
# Using Chocolatey
choco install terraform

# Or download binary from https://www.terraform.io/downloads
```

### Setting Up Your First Project
```bash
mkdir terraform-project
cd terraform-project
touch main.tf
```

### Verify Installation
```bash
terraform version
terraform -help
```

---

## Core Concepts

### Infrastructure as Code (IaC)
Infrastructure defined in configuration files that can be versioned, shared, and reused.

### Declarative vs Imperative
- **Declarative**: Describe the desired end state (Terraform)
- **Imperative**: Describe the steps to reach the end state

### Terraform Workflow
1. **Write**: Author infrastructure as code
2. **Plan**: Preview changes before applying
3. **Apply**: Provision reproducible infrastructure

### Key Components
- **Configuration Files**: `.tf` files defining resources
- **State**: Current state of infrastructure
- **Providers**: Plugins to interact with cloud platforms
- **Resources**: Infrastructure components (VMs, networks, etc.)
- **Modules**: Reusable configuration packages

---

## Configuration Language (HCL)

### HashiCorp Configuration Language (HCL)
Terraform uses HCL, a declarative language designed for infrastructure.

### Basic Syntax

#### Blocks
```hcl
block_type "block_label" "block_name" {
  argument = "value"
  nested_block {
    argument = "value"
  }
}
```

#### Comments
```hcl
# Single line comment

/*
Multi-line
comment
*/

// Also single line comment
```

#### String Interpolation
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "Hello, ${var.name}!"
  }
}
```

#### Lists
```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

#### Maps
```hcl
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-guide"
  }
}
```

#### Objects
```hcl
variable "server_config" {
  type = object({
    instance_type = string
    volume_size   = number
    enable_monitoring = bool
  })
}
```

---

## Providers

### What are Providers?
Providers are plugins that interact with cloud platforms, SaaS providers, and APIs.

### Configuring Providers

#### Basic Provider Configuration
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

#### Multiple Provider Configurations
```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

provider "aws" {
  region = "us-west-2"
  alias  = "west"
}

resource "aws_instance" "east_server" {
  provider = aws.east
  ami      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

resource "aws_instance" "west_server" {
  provider = aws.west
  ami      = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
}
```

#### Provider Authentication

**AWS**
```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Or use AWS CLI credentials
# Or use environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```

**Azure**
```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}
```

**Google Cloud**
```hcl
provider "google" {
  credentials = file("account.json")
  project     = "my-project-id"
  region      = "us-central1"
}
```

### Popular Providers
- AWS
- Azure
- Google Cloud Platform
- Kubernetes
- Docker
- GitHub
- Datadog
- PostgreSQL

---

## Resources

### What are Resources?
Resources are the most important element in Terraform. They represent infrastructure objects.

### Resource Syntax
```hcl
resource "resource_type" "resource_name" {
  argument1 = "value1"
  argument2 = "value2"
  
  nested_block {
    argument = "value"
  }
}
```

### AWS Examples

#### EC2 Instance
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
    Environment = "Production"
  }
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}
```

#### S3 Bucket
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-unique-bucket-name-12345"
  
  tags = {
    Name        = "DataBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "data_versioning" {
  bucket = aws_s3_bucket.data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

#### VPC and Networking
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "main-igw"
  }
}
```

### Resource Meta-Arguments

#### depends_on
```hcl
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  depends_on = [aws_security_group.app_sg]
}
```

#### count

> **Live Kubernetes example** → [study/k8s/learning/main.tf](study/k8s/learning/main.tf) — `kubernetes_pod.alpine_worker`
> **Deep dive** → [count vs for_each — Hands-On with Alpine Pods](#count-vs-for_each--hands-on-with-alpine-pods)

`count` creates N **identical** copies of a resource addressed by **index** (0, 1, 2…).

```hcl
resource "aws_instance" "server" {
  count = 3   # creates server[0], server[1], server[2]
  
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "Server-${count.index}"   # count.index = 0, 1, 2
  }
}

# Access one:  aws_instance.server[0].public_ip
# Access all:  aws_instance.server[*].public_ip  → ["ip0", "ip1", "ip2"]
```

**When to use count:**
- All instances are interchangeable (identical worker nodes, replicas)
- On/off toggle: `count = var.enable_feature ? 1 : 0`

**Danger zone:** Removing an item from the *middle* of a list shifts indexes and can trigger unwanted recreations. Use `for_each` for items with distinct identities.

#### for_each

> **Live Kubernetes example** → [study/k8s/learning/main.tf](study/k8s/learning/main.tf) — `kubernetes_pod.alpine_named`
> **Deep dive** → [count vs for_each — Hands-On with Alpine Pods](#count-vs-for_each--hands-on-with-alpine-pods)

`for_each` iterates over a **map** (or `set(string)`) and addresses each resource by its **key**. Removing a key only destroys that one resource — nothing else shifts.

```hcl
variable "instances" {
  type = map(object({
    ami           = string
    instance_type = string
  }))
  default = {
    web = { ami = "ami-0c55b159cbfafe1f0", instance_type = "t2.micro" }
    app = { ami = "ami-0c55b159cbfafe1f0", instance_type = "t2.small" }
  }
}

resource "aws_instance" "servers" {
  for_each = var.instances   # creates servers["web"], servers["app"]
  
  ami           = each.value.ami            # each.value = the object for this key
  instance_type = each.value.instance_type
  
  tags = {
    Name = "${each.key}-server"   # each.key = "web" or "app"
  }
}

# Access one:  aws_instance.servers["web"].public_ip
# Access all:  { for k, v in aws_instance.servers : k => v.public_ip }
#              → { "web" = "ip_web", "app" = "ip_app" }
```

**When to use for_each:**
- Instances have distinct identities or different configurations
- You may need to add or remove specific items without touching others
- The input is naturally a map (e.g., per-service config)

#### lifecycle
```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags]
  }
}
```

#### provider
```hcl
resource "aws_instance" "west" {
  provider = aws.west
  
  ami           = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
}
```

---

## Variables and Outputs

### Input Variables

#### Variable Declaration
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform"
  }
}
```

#### Variable Types
```hcl
# String
variable "region" {
  type    = string
  default = "us-east-1"
}

# Number
variable "instance_count" {
  type    = number
  default = 2
}

# Bool
variable "enable_monitoring" {
  type    = bool
  default = true
}

# List
variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-abc", "subnet-def"]
}

# Map
variable "ami_ids" {
  type = map(string)
  default = {
    us-east-1 = "ami-0c55b159cbfafe1f0"
    us-west-2 = "ami-0d1cd67c26f5fca19"
  }
}

# Object
variable "database_config" {
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    allocated_storage = number
  })
}

# Tuple
variable "network_config" {
  type = tuple([string, number, bool])
}

# Set
variable "security_group_ids" {
  type = set(string)
}

# Any (not recommended)
variable "flexible_var" {
  type = any
}
```

#### Variable Validation
```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  
  validation {
    condition     = can(regex("^t[2-3]\\.(micro|small|medium)$", var.instance_type))
    error_message = "Instance type must be t2 or t3 and micro, small, or medium."
  }
}

variable "environment" {
  type        = string
  description = "Environment name"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

#### Sensitive Variables
```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

### Providing Variable Values

#### Command Line
```bash
terraform apply -var="instance_type=t2.small" -var="region=us-west-2"
```

#### Variable Files (terraform.tfvars)
```hcl
# terraform.tfvars
instance_type = "t2.small"
region        = "us-west-2"
tags = {
  Environment = "production"
  Project     = "web-app"
}
```

```bash
# Auto-loaded: terraform.tfvars or *.auto.tfvars
terraform apply

# Custom file
terraform apply -var-file="production.tfvars"
```

#### Environment Variables
```bash
export TF_VAR_instance_type="t2.small"
export TF_VAR_region="us-west-2"
terraform apply
```

### Output Values

#### Output Declaration
```hcl
output "instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
  sensitive   = false
}

output "all_instance_ips" {
  description = "All instance public IPs"
  value       = aws_instance.server[*].public_ip
}
```

#### Sensitive Outputs
```hcl
output "db_password" {
  value     = aws_db_instance.database.password
  sensitive = true
}
```

#### Using Outputs
```bash
# View outputs after apply
terraform output

# View specific output
terraform output instance_ip

# JSON format
terraform output -json
```

---

## Data Sources

### What are Data Sources?
Data sources allow Terraform to fetch information from providers without managing those resources.

### Data Source Syntax
```hcl
data "resource_type" "name" {
  argument = "value"
}
```

### Examples

#### AWS AMI
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}
```

#### AWS Availability Zones
```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "example" {
  count             = length(data.aws_availability_zones.available.names)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  vpc_id            = aws_vpc.main.id
}
```

#### AWS VPC
```hcl
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

#### Remote State Data Source
```hcl
data "terraform_remote_state" "networking" {
  backend = "s3"
  
  config = {
    bucket = "my-terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.networking.outputs.subnet_id
}
```

#### External Data Source
```hcl
data "external" "example" {
  program = ["python", "${path.module}/get_data.py"]
  
  query = {
    id = "abc123"
  }
}

output "result" {
  value = data.external.example.result
}
```

---

## State Management

### What is Terraform State?
State is how Terraform keeps track of resources it manages. Stored in `terraform.tfstate` file.

### State File Contents
- Resource mappings
- Metadata
- Dependencies
- Outputs

### Local State
By default, state is stored locally in `terraform.tfstate`.

```bash
# View state
terraform show

# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Remove resource from state
terraform state rm aws_instance.web

# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Pull remote state
terraform state pull
```

### Remote State

#### Why Remote State?
- Collaboration
- Security
- Locking
- Backup

#### S3 Backend
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### Azure Storage Backend
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

#### Terraform Cloud Backend
```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "production"
    }
  }
}
```

### State Locking
Prevents concurrent operations that could corrupt state.

```hcl
# DynamoDB for S3 backend locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### State Commands

```bash
# Initialize backend
terraform init

# Migrate state to new backend
terraform init -migrate-state

# View state
terraform show

# List resources
terraform state list

# Show resource details
terraform state show aws_instance.web

# Remove resource from state (doesn't destroy)
terraform state rm aws_instance.web

# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0

# Replace provider configuration
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws

# Move resource
terraform state mv aws_instance.old aws_instance.new

# Pull remote state to local
terraform state pull > terraform.tfstate

# Push local state to remote
terraform state push terraform.tfstate

# Refresh state
terraform refresh
```

### State Best Practices
- Use remote state for team collaboration
- Enable state locking
- Enable encryption
- Version your state files
- Never edit state manually
- Use workspaces for environments
- Backup state regularly

---

## Modules

### What are Modules?
Modules are containers for multiple resources that are used together. Every Terraform configuration has at least one module (root module).

### Module Structure
```
modules/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── compute/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Creating a Module

#### modules/vpc/main.tf
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-${count.index + 1}"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}
```

#### modules/vpc/variables.tf
```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
```

#### modules/vpc/outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}
```

### Using Modules

#### Local Module
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name             = "production-vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]
  
  tags = {
    Name = "WebServer"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
```

#### Registry Module
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = true
  
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

#### GitHub Module
```hcl
module "eks" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v19.0.0"
  
  cluster_name    = "my-cluster"
  cluster_version = "1.27"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}
```

### Module Sources
- Local paths: `./modules/vpc`
- Terraform Registry: `terraform-aws-modules/vpc/aws`
- GitHub: `github.com/user/repo`
- Generic Git: `git::https://example.com/vpc.git`
- S3: `s3::https://s3.amazonaws.com/bucket/vpc.zip`
- HTTP: `https://example.com/vpc.zip`

### Module Best Practices
- Keep modules small and focused
- Use semantic versioning
- Document inputs and outputs
- Provide examples
- Test modules independently
- Use default values wisely
- Avoid hardcoded values
- Use variables for flexibility

---

## Provisioners

### What are Provisioners?
Provisioners execute scripts on local or remote machines during resource creation or destruction.

**Note**: Use provisioners as a last resort. Prefer native provider functionality or configuration management tools.

### Types of Provisioners

#### local-exec
Executes commands on the machine running Terraform.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ip_address.txt"
  }
  
  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' playbook.yml"
  }
}
```

#### remote-exec
Executes commands on the remote resource.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx"
    ]
  }
}
```

#### file
Copies files or directories to the remote resource.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  
  provisioner "file" {
    source      = "app.conf"
    destination = "/tmp/app.conf"
  }
  
  provisioner "file" {
    content     = templatefile("script.sh", { port = 8080 })
    destination = "/tmp/script.sh"
  }
}
```

### Provisioner Options

#### when
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  # Run on creation (default)
  provisioner "local-exec" {
    when    = create
    command = "echo 'Instance created'"
  }
  
  # Run on destruction
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance destroyed'"
  }
}
```

#### on_failure
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  provisioner "local-exec" {
    command    = "some-command-that-might-fail"
    on_failure = continue  # or fail (default)
  }
}
```

### Null Resource with Provisioners
```hcl
resource "null_resource" "example" {
  triggers = {
    cluster_instance_ids = join(",", aws_instance.cluster[*].id)
  }
  
  provisioner "local-exec" {
    command = "echo 'Cluster instances: ${self.triggers.cluster_instance_ids}'"
  }
}
```

---

## Backends

### What are Backends?
Backends determine where Terraform stores state data.

### Local Backend (Default)
```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

### S3 Backend
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Optional
    role_arn       = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
    session_name   = "terraform"
  }
}
```

#### Setup S3 Backend
```hcl
# Create S3 bucket for state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### Azure Storage Backend
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "terraformstateaccount"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### Google Cloud Storage Backend
```hcl
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state-bucket"
    prefix      = "prod"
    credentials = "account.json"
  }
}
```

### Terraform Cloud Backend
```hcl
terraform {
  cloud {
    organization = "my-organization"
    
    workspaces {
      name = "production"
    }
  }
}
```

### Consul Backend
```hcl
terraform {
  backend "consul" {
    address = "consul.example.com"
    scheme  = "https"
    path    = "terraform/state"
  }
}
```

### Backend Configuration

#### Partial Configuration
```hcl
# backend.tf
terraform {
  backend "s3" {}
}
```

```bash
# Initialize with backend config
terraform init \
  -backend-config="bucket=my-bucket" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Or use config file
terraform init -backend-config=backend-config.tfvars
```

#### backend-config.tfvars
```hcl
bucket = "my-terraform-state-bucket"
key    = "prod/terraform.tfstate"
region = "us-east-1"
```

### Migrating Backends
```bash
# Change backend configuration in terraform block
# Then run:
terraform init -migrate-state
```

---

## Workspaces

### What are Workspaces?
Workspaces allow you to manage multiple environments with the same configuration.

### Workspace Commands

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Select workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete dev
```

### Using Workspaces in Configuration

```hcl
# Reference current workspace
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = terraform.workspace == "prod" ? "t2.large" : "t2.micro"
  
  tags = {
    Name        = "server-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

# Conditional resources based on workspace
resource "aws_instance" "prod_only" {
  count = terraform.workspace == "prod" ? 1 : 0
  
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.large"
}

# Workspace-specific variables
locals {
  instance_counts = {
    dev     = 1
    staging = 2
    prod    = 5
  }
  
  instance_count = local.instance_counts[terraform.workspace]
}

resource "aws_instance" "app" {
  count = local.instance_count
  
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "app-${terraform.workspace}-${count.index}"
  }
}
```

### Workspace Best Practices
- Use workspaces for similar environments
- Consider separate state files for very different environments
- Document workspace usage
- Use workspace-specific variable files
- Be careful with workspace-conditional resources

---

## Functions and Expressions

### Numeric Functions

```hcl
# abs - Absolute value
abs(-5)  # 5

# ceil - Round up
ceil(4.3)  # 5

# floor - Round down
floor(4.7)  # 4

# max - Maximum value
max(5, 12, 9)  # 12

# min - Minimum value
min(5, 12, 9)  # 5

# pow - Power
pow(2, 3)  # 8

# signum - Sign of number
signum(-5)  # -1
signum(0)   # 0
signum(5)   # 1
```

### String Functions

```hcl
# chomp - Remove trailing newline
chomp("hello\n")  # "hello"

# format - Format string
format("Hello, %s!", "World")  # "Hello, World!"

# formatlist - Format list
formatlist("server-%s", ["a", "b", "c"])  # ["server-a", "server-b", "server-c"]

# indent - Add indentation
indent(2, "Hello\nWorld")  # "  Hello\n  World"

# join - Join list to string
join(", ", ["a", "b", "c"])  # "a, b, c"

# lower - Lowercase
lower("HELLO")  # "hello"

# upper - Uppercase
upper("hello")  # "HELLO"

# replace - Replace substring
replace("hello world", "world", "terraform")  # "hello terraform"

# split - Split string to list
split(",", "a,b,c")  # ["a", "b", "c"]

# substr - Substring
substr("hello", 1, 3)  # "ell"

# title - Title case
title("hello world")  # "Hello World"

# trim - Remove leading/trailing characters
trim("  hello  ", " ")  # "hello"

# trimprefix - Remove prefix
trimprefix("helloworld", "hello")  # "world"

# trimsuffix - Remove suffix
trimsuffix("helloworld", "world")  # "hello"

# trimspace - Remove whitespace
trimspace("  hello  ")  # "hello"
```

### Collection Functions

```hcl
# chunklist - Split list into chunks
chunklist(["a", "b", "c", "d", "e"], 2)  # [["a", "b"], ["c", "d"], ["e"]]

# coalesce - First non-null value
coalesce("", "", "hello")  # "hello"

# coalescelist - First non-empty list
coalescelist([], ["a", "b"])  # ["a", "b"]

# compact - Remove empty strings
compact(["a", "", "b", "", "c"])  # ["a", "b", "c"]

# concat - Concatenate lists
concat(["a", "b"], ["c", "d"])  # ["a", "b", "c", "d"]

# contains - Check if list contains value
contains(["a", "b", "c"], "b")  # true

# distinct - Remove duplicates
distinct(["a", "b", "a", "c"])  # ["a", "b", "c"]

# element - Get element by index (wraps around)
element(["a", "b", "c"], 4)  # "b" (4 % 3 = 1)

# flatten - Flatten nested lists
flatten([["a", "b"], ["c"]])  # ["a", "b", "c"]

# index - Find index of value
index(["a", "b", "c"], "b")  # 1

# keys - Get map keys
keys({a = 1, b = 2})  # ["a", "b"]

# values - Get map values
values({a = 1, b = 2})  # [1, 2]

# length - Get length
length(["a", "b", "c"])  # 3

# lookup - Get map value with default
lookup({a = 1, b = 2}, "c", 0)  # 0

# matchkeys - Filter by matching keys
matchkeys(["i-abc", "i-def"], ["a", "b"], ["a"])  # ["i-abc"]

# merge - Merge maps
merge({a = 1}, {b = 2})  # {a = 1, b = 2}

# range - Generate number range
range(3)        # [0, 1, 2]
range(1, 4)     # [1, 2, 3]
range(0, 6, 2)  # [0, 2, 4]

# reverse - Reverse list
reverse(["a", "b", "c"])  # ["c", "b", "a"]

# setintersection - Intersection of sets
setintersection(["a", "b"], ["b", "c"])  # ["b"]

# setproduct - Cartesian product
setproduct(["a", "b"], [1, 2])  # [["a", 1], ["a", 2], ["b", 1], ["b", 2]]

# setsubtract - Set subtraction
setsubtract(["a", "b", "c"], ["b"])  # ["a", "c"]

# setunion - Union of sets
setunion(["a", "b"], ["b", "c"])  # ["a", "b", "c"]

# slice - Get slice of list
slice(["a", "b", "c", "d"], 1, 3)  # ["b", "c"]

# sort - Sort list
sort(["c", "a", "b"])  # ["a", "b", "c"]

# sum - Sum numbers
sum([1, 2, 3])  # 6

# transpose - Transpose map of lists
transpose({a = [1, 2], b = [3, 4]})  # {1 = ["a"], 2 = ["a"], 3 = ["b"], 4 = ["b"]}

# zipmap - Create map from lists
zipmap(["a", "b"], [1, 2])  # {a = 1, b = 2}
```

### Encoding Functions

```hcl
# base64encode - Base64 encode
base64encode("Hello")  # "SGVsbG8="

# base64decode - Base64 decode
base64decode("SGVsbG8=")  # "Hello"

# base64gzip - Gzip and base64 encode
base64gzip("Hello World")

# csvdecode - Parse CSV
csvdecode("a,b,c\n1,2,3")

# jsondecode - Parse JSON
jsondecode("{\"hello\":\"world\"}")  # {hello = "world"}

# jsonencode - Encode to JSON
jsonencode({hello = "world"})  # "{\"hello\":\"world\"}"

# urlencode - URL encode
urlencode("hello world")  # "hello+world"

# yamldecode - Parse YAML
yamldecode("hello: world")  # {hello = "world"}

# yamlencode - Encode to YAML
yamlencode({hello = "world"})  # "hello: world\n"
```

### Filesystem Functions

```hcl
# abspath - Absolute path
abspath("./file.txt")

# dirname - Directory name
dirname("/path/to/file.txt")  # "/path/to"

# pathexpand - Expand ~
pathexpand("~/file.txt")

# basename - Base filename
basename("/path/to/file.txt")  # "file.txt"

# file - Read file
file("${path.module}/config.txt")

# fileexists - Check if file exists
fileexists("${path.module}/config.txt")

# fileset - Find files matching pattern
fileset(path.module, "*.tf")

# filebase64 - Read file as base64
filebase64("${path.module}/image.png")

# templatefile - Render template
templatefile("${path.module}/template.tpl", {
  name = "example"
  port = 8080
})
```

### Date and Time Functions

```hcl
# formatdate - Format timestamp
formatdate("YYYY-MM-DD", timestamp())  # "2024-01-15"

# timeadd - Add duration to timestamp
timeadd(timestamp(), "1h")

# timestamp - Current timestamp
timestamp()  # "2024-01-15T10:30:00Z"
```

### Hash and Crypto Functions

```hcl
# base64sha256 - Base64 SHA256 hash
base64sha256("hello")

# base64sha512 - Base64 SHA512 hash
base64sha512("hello")

# bcrypt - Bcrypt hash
bcrypt("password")

# filebase64sha256 - Base64 SHA256 of file
filebase64sha256("${path.module}/file.txt")

# filemd5 - MD5 hash of file
filemd5("${path.module}/file.txt")

# filesha1 - SHA1 hash of file
filesha1("${path.module}/file.txt")

# filesha256 - SHA256 hash of file
filesha256("${path.module}/file.txt")

# filesha512 - SHA512 hash of file
filesha512("${path.module}/file.txt")

# md5 - MD5 hash
md5("hello")

# rsadecrypt - RSA decrypt
rsadecrypt(encrypted_data, private_key)

# sha1 - SHA1 hash
sha1("hello")

# sha256 - SHA256 hash
sha256("hello")

# sha512 - SHA512 hash
sha512("hello")

# uuid - Generate UUID
uuid()  # "3c5a2c5a-1234-5678-90ab-cdef12345678"

# uuidv5 - Generate UUID v5
uuidv5("dns", "terraform.io")
```

### IP Network Functions

```hcl
# cidrhost - Get IP from CIDR
cidrhost("10.0.0.0/16", 5)  # "10.0.0.5"

# cidrnetmask - Get netmask from CIDR
cidrnetmask("10.0.0.0/16")  # "255.255.0.0"

# cidrsubnet - Calculate subnet
cidrsubnet("10.0.0.0/16", 8, 2)  # "10.0.2.0/24"

# cidrsubnets - Calculate multiple subnets
cidrsubnets("10.0.0.0/16", 8, 8, 8)  # ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
```

### Type Conversion Functions

```hcl
# can - Test if expression succeeds
can(regex("^[0-9]+$", "123"))  # true

# try - Try expressions in order
try(var.optional_value, "default")

# tobool - Convert to boolean
tobool("true")  # true

# tolist - Convert to list
tolist(["a", "b"])

# tomap - Convert to map
tomap({a = 1})

# tonumber - Convert to number
tonumber("42")  # 42

# toset - Convert to set
toset(["a", "b", "a"])  # Set with ["a", "b"]

# tostring - Convert to string
tostring(42)  # "42"

# type - Get type
type("hello")  # "string"
```

### Conditional Expressions

```hcl
# Ternary operator
condition ? true_value : false_value

# Example
resource "aws_instance" "web" {
  instance_type = var.environment == "prod" ? "t2.large" : "t2.micro"
}
```

### For Expressions

```hcl
# List comprehension
[for s in var.list : upper(s)]

# Map to list
[for k, v in var.map : "${k}=${v}"]

# List to map
{for s in var.list : s => upper(s)}

# Filtering
[for s in var.list : upper(s) if s != ""]

# Examples
locals {
  # Transform list
  upper_names = [for name in var.names : upper(name)]
  
  # Filter list
  active_servers = [for s in var.servers : s if s.active]
  
  # Create map from list
  name_map = {for name in var.names : name => upper(name)}
  
  # Transform map
  double_values = {for k, v in var.numbers : k => v * 2}
}
```

### Splat Expressions

```hcl
# Get attribute from all elements
var.list[*].id

# Example
resource "aws_instance" "servers" {
  count = 3
  # ...
}

output "all_ips" {
  value = aws_instance.servers[*].public_ip
}

output "all_ids" {
  value = aws_instance.servers[*].id
}
```

### Dynamic Blocks

```hcl
resource "aws_security_group" "example" {
  name = "example"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

---

## Terraform Commands

### Basic Commands

```bash
# Initialize working directory
terraform init

# Show changes required
terraform plan

# Create or update infrastructure
terraform apply

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# Validate configuration
terraform validate

# Format configuration files
terraform fmt

# Get provider documentation
terraform providers

# Output values
terraform output

# Refresh state
terraform refresh

# Get version
terraform version
```

### Init Command

```bash
# Basic init
terraform init

# Upgrade providers
terraform init -upgrade

# Reconfigure backend
terraform init -reconfigure

# Migrate state
terraform init -migrate-state

# Don't configure backend
terraform init -backend=false

# Lock timeout
terraform init -lock-timeout=30s

# Specify plugin directory
terraform init -plugin-dir=/path/to/plugins
```

### Plan Command

```bash
# Basic plan
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Destroy plan
terraform plan -destroy

# Detailed exit code
terraform plan -detailed-exitcode

# Target specific resource
terraform plan -target=aws_instance.web

# Specify var file
terraform plan -var-file="prod.tfvars"

# Specify variable
terraform plan -var="instance_type=t2.large"

# Refresh only
terraform plan -refresh-only

# Parallelism
terraform plan -parallelism=10
```

### Apply Command

```bash
# Basic apply
terraform apply

# Auto approve
terraform apply -auto-approve

# Apply saved plan
terraform apply tfplan

# Target specific resource
terraform apply -target=aws_instance.web

# Specify var file
terraform apply -var-file="prod.tfvars"

# Specify variable
terraform apply -var="instance_type=t2.large"

# Parallelism
terraform apply -parallelism=10

# Refresh only
terraform apply -refresh-only
```

### Destroy Command

```bash
# Basic destroy
terraform destroy

# Auto approve
terraform destroy -auto-approve

# Target specific resource
terraform destroy -target=aws_instance.web

# Specify var file
terraform destroy -var-file="prod.tfvars"
```

### State Commands

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state
terraform state rm aws_instance.web

# Pull remote state
terraform state pull

# Push local state
terraform state push terraform.tfstate

# Replace provider
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws
```

### Import Command

```bash
# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0

# Import with var file
terraform import -var-file="prod.tfvars" aws_instance.web i-1234567890abcdef0
```

### Taint Command (Deprecated)

```bash
# Mark resource for recreation (use replace instead)
terraform taint aws_instance.web

# Untaint resource
terraform untaint aws_instance.web

# New way (Terraform 0.15.2+)
terraform apply -replace="aws_instance.web"
```

### Workspace Commands

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new dev

# Select workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete dev
```

### Output Commands

```bash
# Show all outputs
terraform output

# Show specific output
terraform output instance_ip

# JSON format
terraform output -json

# Raw value
terraform output -raw instance_ip
```

### Graph Command

```bash
# Generate dependency graph
terraform graph

# Generate and view with Graphviz
terraform graph | dot -Tpng > graph.png
```

### Console Command

```bash
# Interactive console
terraform console

# Example usage in console
> var.instance_type
> aws_instance.web.public_ip
> length(var.subnet_ids)
```

### Force-Unlock Command

```bash
# Force unlock state
terraform force-unlock LOCK_ID
```

### Get Command

```bash
# Download and update modules
terraform get

# Update modules
terraform get -update
```

### Login/Logout Commands

```bash
# Login to Terraform Cloud
terraform login

# Logout from Terraform Cloud
terraform logout
```

### Test Command (Experimental)

```bash
# Run tests
terraform test
```

---

## Best Practices

### Project Structure

```
terraform-project/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider versions
├── terraform.tfvars        # Variable values (gitignored)
├── backend.tf              # Backend configuration
├── locals.tf               # Local values
├── data.tf                 # Data sources
├── modules/                # Local modules
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/           # Environment-specific configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── README.md
```

### Naming Conventions

```hcl
# Use underscores for names
resource "aws_instance" "web_server" {}

# Use descriptive names
variable "vpc_cidr_block" {}

# Prefix module outputs
output "vpc_id" {}
output "vpc_public_subnet_ids" {}

# Use plural for lists
variable "availability_zones" {
  type = list(string)
}

# Use singular for single values
variable "vpc_cidr" {
  type = string
}
```

### Code Organization

#### Separate Concerns
```hcl
# versions.tf - Provider versions
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# provider.tf - Provider configuration
provider "aws" {
  region = var.aws_region
}

# variables.tf - Variable declarations
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# locals.tf - Local values
locals {
  common_tags = {
    Project     = "MyProject"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# data.tf - Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# main.tf - Main resources
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  tags = merge(
    local.common_tags,
    {
      Name = "WebServer"
    }
  )
}

# outputs.tf - Output values
output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

### Use Variables Effectively

```hcl
# Provide descriptions
variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t2.micro"
}

# Use validation
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Use sensitive for secrets
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Provide defaults where appropriate
variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}
```

### Use Modules

```hcl
# Create reusable modules
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name            = "production-vpc"
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  
  tags = local.common_tags
}

# Use registry modules
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"
  
  cluster_name    = "my-cluster"
  cluster_version = "1.27"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}
```

### Use Remote State

```hcl
# Store state remotely
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Reference remote state
data "terraform_remote_state" "networking" {
  backend = "s3"
  
  config = {
    bucket = "my-terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Use Locals for Computed Values

```hcl
locals {
  # Computed values
  vpc_cidr_blocks = {
    for az in var.availability_zones :
    az => cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, az))
  }
  
  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
  
  # Conditional values
  instance_count = var.environment == "prod" ? 5 : 2
}
```

### Use Data Sources

```hcl
# Get latest AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Use in resources
resource "aws_instance" "web" {
  ami               = data.aws_ami.ubuntu.id
  availability_zone = data.aws_availability_zones.available.names[0]
  instance_type     = var.instance_type
}
```

### Version Constraints

```hcl
terraform {
  required_version = ">= 1.0, < 2.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # >= 5.0, < 6.0
    }
  }
}
```

### Use .gitignore

```gitignore
# .gitignore
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
.terraform.lock.hcl
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
```

### Documentation

```hcl
# Document modules
# modules/vpc/README.md

## VPC Module

This module creates a VPC with public and private subnets.

### Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name            = "my-vpc"
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
}
```

### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vpc_name | Name of VPC | string | n/a |
| vpc_cidr | CIDR block | string | "10.0.0.0/16" |

### Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of VPC |
```

### Testing

```bash
# Validate syntax
terraform validate

# Check formatting
terraform fmt -check

# Plan without applying
terraform plan

# Use -target for incremental testing
terraform plan -target=module.vpc

# Use terraform console for testing
terraform console
> length(var.subnet_ids)
> cidrsubnet(var.vpc_cidr, 8, 1)
```

### Security Best Practices

```hcl
# Don't hardcode secrets
variable "db_password" {
  type      = string
  sensitive = true
}

# Use AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

# Mark outputs as sensitive
output "db_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}

# Use IAM roles instead of access keys
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Enable encryption
resource "aws_s3_bucket" "data" {
  bucket = "my-bucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### Performance Tips

```hcl
# Use -parallelism flag
terraform apply -parallelism=20

# Use -refresh=false when appropriate
terraform plan -refresh=false

# Use -target for large infrastructures
terraform apply -target=module.networking

# Use depends_on sparingly
resource "aws_instance" "web" {
  # Only use when Terraform can't infer dependency
  depends_on = [aws_iam_role_policy.example]
}
```

---

## Advanced Topics

### Dynamic Blocks

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = lookup(ingress.value, "description", null)
    }
  }
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}
```

### Conditional Resources

```hcl
# Using count
resource "aws_instance" "conditional" {
  count = var.create_instance ? 1 : 0
  
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# Using for_each with conditional map
locals {
  instances = var.environment == "prod" ? {
    web = { type = "t2.large" }
    app = { type = "t2.xlarge" }
  } : {
    web = { type = "t2.micro" }
  }
}

resource "aws_instance" "servers" {
  for_each = local.instances
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.type
  
  tags = {
    Name = each.key
  }
}
```

### Custom Validation Rules

```hcl
variable "instance_type" {
  type = string
  
  validation {
    condition = can(regex("^t[2-3]\\.(micro|small|medium|large|xlarge)$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 type."
  }
}

variable "cidr_block" {
  type = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "port" {
  type = number
  
  validation {
    condition     = var.port > 0 && var.port < 65536
    error_message = "Port must be between 1 and 65535."
  }
}
```

### Moved Block (Terraform 1.1+)

```hcl
# Refactoring without recreating resources
moved {
  from = aws_instance.old_name
  to   = aws_instance.new_name
}

moved {
  from = module.old_module
  to   = module.new_module
}
```

### Preconditions and Postconditions

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  lifecycle {
    precondition {
      condition     = data.aws_ami.ubuntu.architecture == "x86_64"
      error_message = "AMI must be x86_64 architecture."
    }
    
    postcondition {
      condition     = self.instance_state == "running"
      error_message = "Instance must be in running state."
    }
  }
}
```

### Template Files

```hcl
# user_data.sh.tpl
#!/bin/bash
echo "Hello, ${name}!"
echo "Environment: ${environment}"
apt-get update
apt-get install -y ${package}

# main.tf
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    name        = "World"
    environment = var.environment
    package     = "nginx"
  })
}
```

### Sensitive Data Handling

```hcl
# Using AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/master-password"
}

resource "aws_db_instance" "main" {
  # ...
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}

# Using environment variables
variable "api_key" {
  type      = string
  sensitive = true
}

# Set via: export TF_VAR_api_key="secret"
```

### Partial Configuration

```hcl
# backend.tf
terraform {
  backend "s3" {}
}

# backend-dev.conf
bucket = "dev-terraform-state"
key    = "terraform.tfstate"
region = "us-east-1"

# backend-prod.conf
bucket = "prod-terraform-state"
key    = "terraform.tfstate"
region = "us-east-1"
```

```bash
# Initialize with specific backend
terraform init -backend-config=backend-dev.conf
```

### Debugging

```bash
# Enable detailed logging
export TF_LOG=TRACE
export TF_LOG_PATH=terraform.log

# Log levels: TRACE, DEBUG, INFO, WARN, ERROR

# Disable logging
unset TF_LOG

# Debug specific provider
export TF_LOG_PROVIDER=TRACE

# Core vs provider logging
export TF_LOG_CORE=DEBUG
export TF_LOG_PROVIDER=TRACE
```

### Terraform Cloud Integration

```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      tags = ["networking", "production"]
    }
  }
}

# Or specific workspace
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "production-network"
    }
  }
}
```

---

## Real-World Examples

### Complete AWS Infrastructure

```hcl
# versions.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/infrastructure.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# provider.tf
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# locals.tf
locals {
  common_tags = {
    Project     = "WebApp"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  public_subnet_cidrs  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
}

# data.tf
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# vpc.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.environment}-private-${count.index + 1}"
    Type = "private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  
  tags = {
    Name = "${var.environment}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.environment}-nat-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = {
    Name = "${var.environment}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# security-groups.tf
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-web-sg"
  }
}

# alb.tf
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  tags = {
    Name = "${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
  
  tags = {
    Name = "${var.environment}-web-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# auto-scaling.tf
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.environment == "prod" ? "t3.small" : "t3.micro"
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))
  
  tag_specifications {
    resource_type = "instance"
    
    tags = {
      Name = "${var.environment}-web-server"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-web-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  
  min_size         = var.environment == "prod" ? 2 : 1
  max_size         = var.environment == "prod" ? 10 : 2
  desired_capacity = var.environment == "prod" ? 3 : 1
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.environment}-web-asg"
    propagate_at_launch = false
  }
}

# outputs.tf
output "vpc_id" {
  description = "ID of VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}
```

### Kubernetes Cluster (EKS)

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"
  
  cluster_name    = "${var.environment}-cluster"
  cluster_version = "1.27"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  cluster_endpoint_public_access = true
  
  eks_managed_node_groups = {
    main = {
      min_size     = 2
      max_size     = 10
      desired_size = 3
      
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }
      
      tags = local.common_tags
    }
  }
  
  tags = local.common_tags
}
```

### Multi-Region Setup

```hcl
# providers.tf
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}

# main.tf
module "vpc_east" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.us_east
  }
  
  vpc_name = "east-vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "vpc_west" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.us_west
  }
  
  vpc_name = "west-vpc"
  vpc_cidr = "10.1.0.0/16"
}
```

---

## Troubleshooting

### Common Errors

#### State Lock Error
```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException
```

**Solution:**
```bash
# List locks
aws dynamodb scan --table-name terraform-locks

# Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

#### Provider Plugin Error
```
Error: Could not load plugin
```

**Solution:**
```bash
# Remove cached plugins
rm -rf .terraform

# Re-initialize
terraform init
```

#### Invalid Resource Reference
```
Error: Reference to undeclared resource
```

**Solution:**
- Check resource names and types
- Ensure resource is defined before use
- Check for typos

#### Cycle Error
```
Error: Cycle: resource depends on itself
```

**Solution:**
- Review dependencies
- Remove circular dependencies
- Use depends_on carefully

#### Invalid Count/For_Each
```
Error: Invalid count argument
```

**Solution:**
```hcl
# Count must be known at plan time
# BAD
count = length(aws_instance.web[*].id)

# GOOD
count = var.instance_count
```

### Debugging Techniques

#### Enable Detailed Logging
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
```

#### Use terraform console
```bash
terraform console
> var.vpc_cidr
> cidrsubnet(var.vpc_cidr, 8, 1)
> length(var.subnet_ids)
```

#### Targeted Operations
```bash
# Target specific resource
terraform plan -target=aws_instance.web

# Refresh specific resource
terraform refresh -target=aws_instance.web
```

#### State Inspection
```bash
# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Show all attributes
terraform show
```

### Recovery Procedures

#### Corrupted State
```bash
# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Or pull from remote
terraform state pull > terraform.tfstate
```

#### Import Existing Resources
```bash
# Import EC2 instance
terraform import aws_instance.web i-1234567890abcdef0

# Import S3 bucket
terraform import aws_s3_bucket.data my-bucket-name

# Import VPC
terraform import aws_vpc.main vpc-12345678
```

#### Refresh State
```bash
# Refresh all resources
terraform refresh

# Refresh and update
terraform apply -refresh-only
```

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  TF_VERSION: 1.5.0

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: ${{ env.TF_VERSION }}
    
    - name: Terraform Format
      run: terraform fmt -check
    
    - name: Terraform Init
      run: terraform init
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Terraform Plan
      if: github.event_name == 'pull_request'
      run: terraform plan -no-color
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
image:
  name: hashicorp/terraform:1.5
  entrypoint: [""]

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_STATE_NAME: default

cache:
  paths:
    - ${TF_ROOT}/.terraform

before_script:
  - cd ${TF_ROOT}
  - terraform init

stages:
  - validate
  - plan
  - apply

validate:
  stage: validate
  script:
    - terraform fmt -check
    - terraform validate

plan:
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
    expire_in: 1 week
  only:
    - merge_requests

apply:
  stage: apply
  script:
    - terraform apply -auto-approve tfplan
  dependencies:
    - plan
  only:
    - main
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        TF_VERSION = '1.5.0'
        AWS_CREDENTIALS = credentials('aws-credentials')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        
        stage('Terraform Format') {
            steps {
                sh 'terraform fmt -check'
            }
        }
        
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }
        
        stage('Approval') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Apply Terraform changes?',
                      ok: 'Apply'
            }
        }
        
        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            steps {
                sh 'terraform apply tfplan'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

### Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  terraformVersion: '1.5.0'

stages:
- stage: Validate
  jobs:
  - job: Validate
    steps:
    - task: TerraformInstaller@0
      inputs:
        terraformVersion: $(terraformVersion)
    
    - task: TerraformCLI@0
      displayName: 'Terraform Init'
      inputs:
        command: 'init'
        backendType: 'azurerm'
        backendServiceArm: 'Azure Connection'
    
    - task: TerraformCLI@0
      displayName: 'Terraform Format'
      inputs:
        command: 'fmt'
        commandOptions: '-check'
    
    - task: TerraformCLI@0
      displayName: 'Terraform Validate'
      inputs:
        command: 'validate'

- stage: Plan
  dependsOn: Validate
  condition: succeeded()
  jobs:
  - job: Plan
    steps:
    - task: TerraformCLI@0
      displayName: 'Terraform Plan'
      inputs:
        command: 'plan'
        commandOptions: '-out=tfplan'

- stage: Apply
  dependsOn: Plan
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: Apply
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: TerraformCLI@0
            displayName: 'Terraform Apply'
            inputs:
              command: 'apply'
              commandOptions: 'tfplan'
```

---

## count vs for_each — Hands-On with Alpine Pods

> **Live example**: [study/k8s/learning/](study/k8s/learning/)
> Run `terraform init && terraform apply` in that directory to deploy the pods.

### The Core Problem count Has

`count` gives each resource an **index** (0, 1, 2). This is fragile when you remove items from the middle:

```
Before: ["web", "api", "batch"]   → pod[0]=web  pod[1]=api  pod[2]=batch
Remove "api":
After:  ["web", "batch"]          → pod[0]=web  pod[1]=batch
                                           ↑           ↑
                                       unchanged   RECREATED (was batch, index shifted)
```

Terraform sees index 1 changed from `api` to `batch` and **destroys + recreates** the batch pod even though you only wanted to remove the api pod.

### How for_each Fixes It

`for_each` uses a **key** (string) as the stable identity instead of a position:

```
Before: { web=..., api=..., batch=... }  → pod["web"]  pod["api"]  pod["batch"]
Remove "api":
After:  { web=...,          batch=... }  → pod["web"]              pod["batch"]
                                                ↑                        ↑
                                            unchanged               unchanged  ✅
```

Only the `api` pod is destroyed. Everything else is untouched.

### count — When to Use It

```hcl
# ✅ Good: identical worker nodes — interchangeable, number is all that matters
resource "kubernetes_pod" "alpine_worker" {
  count = var.worker_count   # creates pods[0], pods[1], pods[2]

  metadata {
    name      = "alpine-worker-${count.index}"   # count.index = 0, 1, 2...
    namespace = "terraform-learning"
  }
  spec {
    container {
      name    = "alpine"
      image   = "alpine:3.19"
      command = ["sh", "-c", "echo Worker ${count.index} && sleep 3600"]
    }
  }
}

# Access specific pod:     kubernetes_pod.alpine_worker[0]
# Access all pod names:    kubernetes_pod.alpine_worker[*].metadata[0].name
# → ["alpine-worker-0", "alpine-worker-1", "alpine-worker-2"]
```

```hcl
# ✅ Also good: on/off toggle (count = 0 or 1)
resource "kubernetes_config_map" "demo_info" {
  count = var.worker_count > 0 ? 1 : 0   # only exists when workers are running
  # ...
}
```

### for_each — When to Use It

```hcl
variable "named_pods" {
  type = map(object({
    command     = list(string)
    environment = string
  }))
  default = {
    "web"   = { command = ["sh", "-c", "sleep 3600"], environment = "frontend" }
    "api"   = { command = ["sh", "-c", "sleep 3600"], environment = "backend"  }
    "batch" = { command = ["sh", "-c", "sleep 3600"], environment = "worker"   }
  }
}

resource "kubernetes_pod" "alpine_named" {
  for_each = var.named_pods   # iterates over the map

  metadata {
    name   = "alpine-${each.key}"              # each.key   = "web", "api", "batch"
    labels = { environment = each.value.environment }  # each.value = the object for this key
  }
  spec {
    container {
      name    = "alpine"
      image   = "alpine:3.19"
      command = each.value.command             # each pod gets its own command
      env {
        name  = "POD_ROLE"
        value = each.key
      }
    }
  }
}

# Access specific pod:       kubernetes_pod.alpine_named["web"]
# Access all as a map:       { for k, pod in kubernetes_pod.alpine_named : k => pod.metadata[0].name }
# → { "web" = "alpine-web", "api" = "alpine-api", "batch" = "alpine-batch" }
```

### Output Differences

```hcl
# count → outputs a LIST (ordered, indexed)
output "count_pod_names" {
  value = kubernetes_pod.alpine_worker[*].metadata[0].name
  # ["alpine-worker-0", "alpine-worker-1", "alpine-worker-2"]
}

# for_each → outputs a MAP (keyed, unordered)
output "foreach_pod_names" {
  value = { for k, pod in kubernetes_pod.alpine_named : k => pod.metadata[0].name }
  # { "api" = "alpine-api", "batch" = "alpine-batch", "web" = "alpine-web" }
}
```

### Cheat Sheet

| | `count` | `for_each` |
|---|---|---|
| Input type | `number` | `map` or `set(string)` |
| Access key | `count.index` (0, 1, 2…) | `each.key`, `each.value` |
| Resource address | `resource.name[0]` | `resource.name["key"]` |
| Splat output | `resource.name[*].attr` → list | `for k, v in resource.name : k => v.attr` → map |
| Safe to remove middle item? | ❌ Shifts indexes, may recreate others | ✅ Only the keyed item is destroyed |
| Best for | Identical replicas, on/off toggle | Items with distinct identities or configs |

### Experiment: See the Problem Live

```bash
cd study/k8s/learning
terraform init
terraform apply          # creates 3 workers + 3 named pods

# Now open variables.tf and change named_pods to remove "api"
# Then run:
terraform plan           # see that only alpine-api is destroyed
                         # alpine-web and alpine-batch are UNCHANGED

# Compare: change worker_count from 3 to 2
terraform plan           # see that alpine-worker-2 is destroyed (end of list, safe)

# Dangerous count scenario:
# Change worker_count back to 3, then change the list order:
# Terraform would recreate pods at shifted indexes
```

---

## Conclusion

This guide covers Terraform from basics to advanced topics. Key takeaways:

1. **Infrastructure as Code**: Define and manage infrastructure declaratively
2. **State Management**: Critical for tracking resources and collaboration
3. **Modules**: Reusable, composable infrastructure components
4. **Best Practices**: Version control, remote state, testing, documentation
5. **Security**: Handle secrets properly, use encryption, follow least privilege
6. **CI/CD**: Automate validation, planning, and deployment

### Next Steps

1. Practice with simple examples
2. Build real projects
3. Contribute to open source modules
4. Explore Terraform Cloud/Enterprise
5. Learn about testing frameworks (Terratest, Kitchen-Terraform)
6. Join Terraform community forums

### Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Learn Terraform](https://learn.hashicorp.com/terraform)
- [Terraform Best Practices](https://www.terraform-best-practices.com)

Happy Terraforming!
