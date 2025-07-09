![AWS Terraform CI/CD Project](https://img.shields.io/badge/Built%20with-Terraform-blue?style=flat-square)
![GitLab CI/CD](https://img.shields.io/badge/CI%2FCD-GitLab-orange?style=flat-square)
![AWS](https://img.shields.io/badge/Cloud-AWS-brightgreen?style=flat-square)


# 3-Tier Web Application on AWS with Terraform & GitLab CI/CD

This project demonstrates deploying a 3-tier architecture (Web, App, DB) on AWS using **Terraform** for Infrastructure as Code (IaC) and **GitLab CI/CD** for automation.

## 📌 Architecture Overview

```
            +---------------+
            |  Load Balancer|
            +------+--------+
                   |
        +----------+----------+
        |                     |
    +---+---+             +---+---+
    | EC2-1 |             | EC2-2 |   <- App Layer (Autoscaled EC2)
    +-------+             +-------+
        |                     |
        +----------+----------+
                   |
            +------+--------+
            |   RDS MySQL    |    <- Database Layer
            +---------------+
```

---

## 🛠️ Tech Stack

- **AWS Services**: VPC, EC2, ALB, RDS, S3, IAM
- **Terraform**: Infrastructure provisioning
- **GitLab CI/CD**: Automation for plan/apply pipeline
- **Ubuntu/Linux**: Server setup

---

## 📁 Repository Structure

```
.
├── terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── ec2.tf
│   ├── rds.tf
│   ├── alb.tf
├── scripts
│   └── user_data.sh
├── .gitlab-ci.yml
└── README.md
```

---

## ⚙️ Setup Instructions

### 1. Clone the Repo
```bash
git clone https://github.com/yourusername/aws-terraform-3tier.git
cd aws-terraform-3tier
```

### 2. Initialize and Apply Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. GitLab CI/CD Setup
- Push repo to GitLab
- Add environment variables:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `TF_STATE_BUCKET` (optional)

### 4. Trigger Pipeline
CI/CD will:
- Run `terraform fmt`, `validate`
- Execute `plan` and `apply`

---

## 🔒 Security & Best Practices
- IAM roles with least privilege
- Use of remote backend (e.g., S3) for state file
- Output masking of secrets in CI/CD logs

---

## 📚 Files

### terraform/vpc.tf
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}
```

### terraform/ec2.tf
```hcl
resource "aws_launch_template" "web" {
  name_prefix   = "web-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type

  user_data = base64encode(file("../scripts/user_data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web-instance"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web_tg.arn]
  health_check_type   = "EC2"
  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}
```

### terraform/rds.tf
```hcl
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = var.db_name
  username             = var.db_user
  password             = var.db_pass
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "main-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id
  tags = {
    Name = "main-db-subnet-group"
  }
}
```

### terraform/alb.tf
```hcl
resource "aws_lb" "web" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
```

### scripts/user_data.sh
```bash
#!/bin/bash
apt update -y
apt install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html
```

### .gitlab-ci.yml
```yaml
stages:
  - validate
  - plan
  - apply

variables:
  TF_VAR_db_user: "admin"
  TF_VAR_db_pass: "securepass123"

validate:
  stage: validate
  script:
    - terraform init
    - terraform fmt -check
    - terraform validate

plan:
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan

apply:
  stage: apply
  when: manual
  script:
    - terraform apply -auto-approve tfplan
```

---

## 👨‍💻 Author
**Pradeep Mahadevaiah**  
AWS Certified Cloud Engineer | DevOps Enthusiast  
GitHub: [github.com/PradeepMahadevaiah](https://github.com/PradeepMahadevaiah)

---

## 📌 To Do
- [ ] Add monitoring (CloudWatch + SNS)
- [ ] Add S3 for static assets
- [ ] Add route53 + ACM for domain + HTTPS
- [ ] Optional: Switch to Jenkins CI/CD

---

## 🏁 License
MIT License
