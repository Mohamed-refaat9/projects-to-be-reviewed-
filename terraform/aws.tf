provider "aws" {
  region = "us-east-1"
}

############### terraform wordpress project ##################

#1 Create VPC and internet gateway 

resource "aws_vpc" "wordpress_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "wordpress-vpc"
  }
}
resource "aws_internet_gateway" "wordpress_internet_gateway" {
  vpc_id = aws_vpc.wordpress_vpc.id
  tags = {
    Name = "wordpress-internet-gateway"
  }
}
#2 create subnets and route tables 
resource "aws_subnet" "wordpress_web_public_subnet_1" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "wordpress-web-public-subnet-1"
  }
}
resource "aws_subnet" "wordpress_web_public_subnet_2" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "wordpress-web-public-subnet-2"
  }
}
resource "aws_subnet" "wordpress_app_private_subnet_1" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "wordpress-app-private-subnet-1"
  }
}
resource "aws_subnet" "wordpress_app_private_subnet_2" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    Name = "wordpress-app-private-subnet-2 "
  }
}
resource "aws_subnet" "wordpress_DB_private_subnet_1" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "wordpress-db-private-subnet-1"
  }
}
resource "aws_subnet" "wordpress_DB_private_subnet_2" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    Name = "wordpress-db-private-subnet-2"
  }
}
#3 associate route tables with public subnets 
resource "aws_route_table" "wordpress_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_internet_gateway.id
  }
  tags = {
    Name = "wordpress-route-table"
  }
}
resource "aws_route_table_association" "wordpress_route_table_association" {
  subnet_id      = aws_subnet.wordpress_web_public_subnet_1.id
  route_table_id = aws_route_table.wordpress_route_table.id
}
resource "aws_route_table_association" "wordpress_route_table_association_2" {
  subnet_id      = aws_subnet.wordpress_web_public_subnet_2.id
  route_table_id = aws_route_table.wordpress_route_table.id
}
#4 associate route tables with private subnets
resource "aws_route_table" "wordpress_private_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id
  tags = {
    Name = "wordpress-private-route-table"
  }
}
resource "aws_route_table_association" "wordpress_private_route_table_association_1" {
  subnet_id      = aws_subnet.wordpress_app_private_subnet_1.id
  route_table_id = aws_route_table.wordpress_private_route_table.id
}
resource "aws_route_table_association" "wordpress_private_route_table_association_2" {
  subnet_id      = aws_subnet.wordpress_app_private_subnet_2.id
  route_table_id = aws_route_table.wordpress_private_route_table.id
}
resource "aws_route_table_association" "wordpress_private_route_table_association_3" {
  subnet_id      = aws_subnet.wordpress_DB_private_subnet_1.id
  route_table_id = aws_route_table.wordpress_private_route_table.id
}
resource "aws_route_table_association" "wordpress_private_route_table_association_4" {
  subnet_id      = aws_subnet.wordpress_DB_private_subnet_2.id
  route_table_id = aws_route_table.wordpress_private_route_table.id
}   
#5 create security groups for the internal compononts 
#A application load balancer 
resource "aws_security_group" "Alb_sg" {
  vpc_id = aws_vpc.wordpress_vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Alb_sg"
  }
  name = "wordpress-alb-sg"
  description = "security group for ALB"
}
#B EC2 instances
resource "aws_security_group" "EC2_sg" {
  vpc_id = aws_vpc.wordpress_vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.Alb_sg.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "EC2_sg"
  }
  name = "wordpress-ec2-sg"
  description = "security group for EC2 instances"
}
#C RDS 
resource "aws_security_group" "RDS_sg" {
  vpc_id = aws_vpc.wordpress_vpc.id
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.EC2_sg.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "RDS_sg"
  }
  name = "wordpress-rds-sg"
  description = "security group for RDS"
}
#6 creating key pair 
resource "aws_key_pair" "wordpress_key_pair" {
  key_name = "wordpress-key-pair"
  public_key = file("~/.ssh/wordpress.pub")
}

#7 creating launch templates for the ec2 instances 
resource "aws_launch_template" "wordpress_launch_template" {
  name = "wordpress-launch-template"
  description = "Launch template for WordPress EC2 instances"
  image_id = "ami-059396c15ac6c9d22"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.EC2_sg.id]
  key_name = aws_key_pair.wordpress_key_pair.key_name
  tags = {
    name = "wordpress-launch-template"
  }
  user_data = base64encode(file("${path.module}/userdata.sh",))
tag_specifications {
  resource_type = "instance"
  tags = {
    name = "wordpress-instance"
    project ="wordpress-ha"
    ManagedBy = "terraform"
  }
}
monitoring {
  enabled = false
}
block_device_mappings {
device_name = "/dev/xvda"

ebs {
  volume_size = 8
  volume_type = "gp3"
  delete_on_termination = true
}
}
update_default_version = true
}
#8 creating auto scaling group 
resource "aws_autoscaling_group" "wordpress_autoscaling_group" {
  name = "wordpress-ASG"
  min_size = 1
  desired_capacity = 1
  max_size = 2
  launch_template {
    id = aws_launch_template.wordpress_launch_template.id
    version = aws_launch_template.wordpress_launch_template.latest_version
  }
  health_check_type = "ELB"
  health_check_grace_period = 360
  vpc_zone_identifier = [aws_subnet.wordpress_app_private_subnet_1.id, aws_subnet.wordpress_app_private_subnet_2.id]
  force_delete = true
  tag {
    key = "Name"
    value = "wordpress-ASG"
    propagate_at_launch = true
  }
  tag {
    key = "Project"
    value = "wordpress-ha"
    propagate_at_launch = true
  }
  tag {
    key = "ManagedBy"
    value = "terraform"
    propagate_at_launch = true
  }
}
#9 creating the application load balancer 
resource "aws_lb" "wordpress_alb" {
  name = "wordpress-alb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [aws_security_group.Alb_sg.id]
  subnets = [aws_subnet.wordpress_web_public_subnet_1.id, aws_subnet.wordpress_web_public_subnet_2.id]
  enable_deletion_protection = false
  tags = {
  Name = "wordpress-alb"
  Project = "wordpress-ha"
  ManagedBy = "terraform"
}
}
#10 creating the target group 
resource "aws_lb_target_group" "wordpress_target_group" {
  name = "wordpress-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.wordpress_vpc.id  
  target_type = "instance" 
  health_check {
    interval = 30
    path = "/"
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
  tags = {
    Name = "wordpress-target-group"
    Project = "wordpress-ha"
    ManagedBy = "terraform"
  }
}
#11 let's create the listener configuration 
resource "aws_lb_listener" "wordpress_listener" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.wordpress_target_group.arn
  }
}
#12 let's attach our target group to the auto scaling group 
resource "aws_autoscaling_attachment" "wordpress_attachment" {
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling_group.name 
  lb_target_group_arn = aws_lb_target_group.wordpress_target_group.arn
}
#13 creating a subnet group for the rds 
resource "aws_db_subnet_group" "wordpress_db_subnet_group" {
  name = "wordpress-db-subnet-group"
  description = "Subnet group for WordPress RDS instance"
  subnet_ids = [aws_subnet.wordpress_DB_private_subnet_1.id, aws_subnet.wordpress_DB_private_subnet_2.id]
    tags = {
    Name      = "wordpress-db-subnet-group"
    Project   = "wordpress-ha"
    ManagedBy = "terraform"
  }
}
#14 let's create the MYSQL database 
resource "aws_db_instance" "wordpress_db" {
  db_name = "wordpress"
  identifier = "wordpress-db"
  db_subnet_group_name = aws_db_subnet_group.wordpress_db_subnet_group.name
  instance_class = "db.t3.micro"
  publicly_accessible = false
  engine = "mysql"
  engine_version = "8.0"
  multi_az = false
  skip_final_snapshot = true
  port = 3306
  vpc_security_group_ids = [aws_security_group.RDS_sg.id]
  allocated_storage = 20
  storage_type = "gp2"
  username = "var.db_username"
  password = "var.db_password"
  parameter_group_name = "default.mysql8.0"
  deletion_protection = false 
  backup_retention_period = 0
  tags = {
    Name      = "wordpress-db"
    Project   = "wordpress-ha"
    ManagedBy = "terraform"
  }
}
