# Zero-Budget High Availability WordPress Deployment on AWS using Terraform

## Overview

This project demonstrates how to deploy a highly available three-tier WordPress architecture on AWS using Terraform while minimizing costs for educational purposes.

The objective was not to build a production-grade enterprise platform with every AWS service available, but rather to understand and implement the core cloud concepts behind:

* Infrastructure as Code (Terraform)
* High Availability
* Auto Scaling
* Load Balancing
* Private Networking
* Database Isolation
* Immutable Infrastructure using Golden AMIs

---

# Architecture

```
                Internet
                    |
                    |
          +-------------------+
          | Application Load  |
          |     Balancer      |
          +-------------------+
                    |
            Target Group
                    |
          +------------------+
          | Auto Scaling     |
          |      Group       |
          +------------------+
             |            |
             |            |
      +-------------+ +-------------+
      | EC2 Private | | EC2 Private |
      | Application | | Application |
      |   Instance  | |   Instance  |
      +-------------+ +-------------+
             |
             |
      +----------------+
      |  Amazon RDS    |
      |     MySQL      |
      +----------------+
```

---

# Project Goals

* Deploy AWS infrastructure using Terraform.
* Create a highly available network design.
* Separate application and database tiers.
* Keep the database private.
* Automatically replace failed EC2 instances.
* Use a Golden AMI to reduce provisioning time.
* Stay as close to AWS Free Tier as possible.

---

# Technologies Used

* Terraform
* AWS VPC
* AWS EC2
* AWS Auto Scaling Group
* AWS Application Load Balancer
* AWS Target Groups
* AWS Security Groups
* AWS RDS MySQL
* AWS Launch Templates
* Amazon Linux 2023
* Apache HTTP Server
* PHP
* WordPress

---

# Network Design

## VPC

```
CIDR: 10.0.0.0/16
```

DNS Hostnames and DNS Support are enabled.

---

## Public Subnets

Used for:

* Application Load Balancer
* Temporary Golden AMI Builder Instance

```
10.0.1.0/24
10.0.2.0/24
```

---

## Private Application Subnets

Used for:

* Auto Scaling Group EC2 instances

```
10.0.3.0/24
10.0.4.0/24
```

---

## Private Database Subnets

Used for:

* Amazon RDS MySQL

```
10.0.5.0/24
10.0.6.0/24
```

---

# Security Groups

## Application Load Balancer

Inbound:

* HTTP 80 from anywhere

Outbound:

* All traffic

---

## EC2 Application Instances

Inbound:

* HTTP 80 only from ALB Security Group

Outbound:

* All traffic

---

## RDS MySQL

Inbound:

* MySQL 3306 only from EC2 Security Group

Outbound:

* All traffic

---

# Golden AMI Strategy

A temporary EC2 instance was launched in a public subnet.

The following packages were installed:

* Apache
* PHP
* PHP MySQL Extension
* PHP GD
* PHP XML
* PHP MBString
* PHP ZIP
* WordPress

After verifying that the WordPress installer loaded successfully, a Golden AMI was created.

The temporary builder instance was then terminated.

The Auto Scaling Group launches all future instances from this AMI.

User Data became very simple:

```bash
#!/bin/bash

sudo systemctl enable httpd
sudo systemctl start httpd
```

---

# Auto Scaling Group

Configuration:

* Minimum Capacity: 1
* Desired Capacity: 1
* Maximum Capacity: 2

Launch Template:

* Golden AMI
* t3.micro
* Private Subnets

Health Check Type:

```
ELB
```

This allows the Auto Scaling Group to replace unhealthy application instances.

---

# Application Load Balancer

Listener:

* HTTP 80

Default Action:

* Forward requests to Target Group

---

# Target Group

Protocol:

* HTTP

Port:

* 80

Target Type:

* Instance

Health Check:

* Path: /

This ensures traffic is only routed to healthy EC2 instances.

---

# Amazon RDS

Engine:

* MySQL Community Edition

Configuration:

* db.t3.micro
* Single AZ
* Private Subnets
* Not Publicly Accessible
* Backup Retention: 0
* Skip Final Snapshot: Enabled

This configuration was intentionally selected to minimize costs.

---

# High Availability Validation

The project was tested by manually terminating an EC2 instance.

Observed behavior:

1. EC2 instance terminated.
2. Auto Scaling Group detected reduced capacity.
3. New EC2 instance launched from Golden AMI.
4. Target Group health checks executed.
5. ALB routed traffic to the healthy replacement instance.
6. Existing WordPress data remained available because it was stored in RDS.

This validated the self-healing capability of the infrastructure.

---

# Cost Optimization Decisions

This project intentionally avoids additional AWS services to remain educational and budget-friendly.

## Decisions

### HTTP instead of HTTPS

Reason:

* Avoid ACM and domain management complexity during learning.

---

### Single AZ RDS

Reason:

* Multi-AZ doubles database cost.

---

### No NAT Gateway

Reason:

* NAT Gateway incurs continuous charges.

A Golden AMI approach was used instead.

---

### No Bastion Host

Reason:

* Minimize running resources.

---

### No EFS

Reason:

* Keep the project as close to Free Tier as possible.

Uploaded media persistence is outside the scope of this version.

---

# Challenges Encountered

## WordPress Database Connection Error

Cause:

* Incorrect RDS endpoint supplied during WordPress installation.

Resolution:

* Verified RDS status.
* Verified security groups.
* Corrected database host.
* WordPress successfully generated wp-config.php.

---

## Auto Scaling Validation

Initial observation:

* Replacement instance did not appear immediately.

Explanation:

* EC2 launch.
* Boot process.
* User Data execution.
* Target Group health checks.

After a short delay, the instance became healthy.

---

## Uploaded Images Lost After Instance Replacement

Reason:

Application servers are immutable.

Local EC2 storage is ephemeral.

Future improvements may include shared storage.

---

# Future Improvements

* HTTPS support
* ACM SSL certificates
* Shared storage for media uploads
* Terraform modules
* Remote Terraform state
* CloudWatch monitoring
---
# Lessons Learned

* Infrastructure as Code principles.
* Three-tier application architecture.
* High Availability concepts.
* Security Group design.
* Application Load Balancer behavior.
* Target Group health checks.
* Auto Scaling lifecycle.
* Immutable Infrastructure.
* Golden AMI workflow.
* Private networking.
* RDS integration with WordPress.
* Cloud cost optimization.

---

# Conclusion

This project demonstrates how a highly available WordPress deployment can be implemented using Terraform and core AWS services while keeping infrastructure costs low for learning purposes.

The architecture separates compute from persistent storage, automatically replaces failed application servers, and provides a strong foundation for future enhancements.
