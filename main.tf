# VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "flex-vpc"
  }
}

# Private Subnet 
resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "fle-prv-sub"
  }
}

# public subnet 
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "flex-pub-sub"
  }
}

# Private Subnet 2
resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "flex-prv-sub-2"
  }
}

# public subnet 2
resource "aws_subnet" "public-subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "flex-pub-sub-2"
  }
}

# internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "flex-gw"
  }
}

# Elastic/static IP
resource "aws_eip" "ip" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "flex-rt"
  }
}

# rt association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.rt.id
}

# rt association 2
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.rt.id
}


# route table for 
resource "aws_route_table" "p-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "flex-p-rt"
  }
}

# rt association
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.p-rt.id
}

# rt association
resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.private-subnet-2.id 
  route_table_id = aws_route_table.p-rt.id
}

# Create frontend Security Group
resource "aws_security_group" "frontend-sg" {
  name        = "frontend-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
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
    Name = "flex-sg-fe"
  }
}

# Create Backend Security Group
resource "aws_security_group" "backend-sg" {
  name        = "backend-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "MYSQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend-sg.id]
  }
  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "flex-sg-be"
  }
}

# key pair
resource "aws_key_pair" "key" {
  key_name   = "flex-keypair"
  public_key = file("./flex-keypair.pub")
}

# # instance
# resource "aws_instance" "ec2" {
#   ami                         = "ami-03035978b5aeb1274"
#   instance_type               = "t3.micro"
#   subnet_id                   = aws_subnet.public-subnet.id
#   vpc_security_group_ids      = [aws_security_group.frontend-sg.id]
#   associate_public_ip_address = true
#   key_name                    = aws_key_pair.key.id
#   depends_on                  = [aws_instance.mysql_ec2]
#   user_data                   = local.userdata1

#   tags = {
#     Name = "flex-ec2"
#   }
# }

# # mysql instance
# resource "aws_instance" "mysql_ec2" {
#   ami                         = "ami-03035978b5aeb1274"
#   instance_type               = "t3.micro"
#   subnet_id                   = aws_subnet.private-subnet.id
#   vpc_security_group_ids      = [aws_security_group.backend-sg.id]
#   associate_public_ip_address = false
#   key_name                    = aws_key_pair.key.id
#   user_data                   = local.userdata2

#   tags = {
#     Name = "mysql-flex-ec2"
#   }
# }

# RDS data base
resource "aws_db_instance" "db-main" {
  allocated_storage    = 10
  db_name              = "wordpress"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin123"
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_ids = [ aws_security_group.backend-sg.id ]
  db_subnet_group_name = aws_db_subnet_group.db-subnet.id
  multi_az = true
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "db-subnet" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.private-subnet.id, aws_subnet.private-subnet-2.id]

  tags = {
    Name = "flexdbg"
  }
}

# launch_template
resource "aws_launch_template" "flex-launch_template" {
  image_id             = "ami-064983766e6ab3419"
  instance_type        = "t3.micro"
  key_name             = aws_key_pair.key.id
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.frontend-sg.id]
  }
  user_data = base64encode(local.userdata1)
  tags = {
    Name = "flex-launch_template"
  }
}


# #Auto scaling group  
resource "aws_autoscaling_group" "ASG" {
  name = "ASG"
  max_size = 4
  min_size = 1
  desired_capacity = 2
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true
  launch_template {
    id = aws_launch_template.flex-launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public-subnet.id, aws_subnet.public-subnet-2.id]
  target_group_arns = [aws_lb_target_group.flex-tg.arn]
  tag {
    key = "Name"
    value = "asg"
    propagate_at_launch = true
  }
}

# Auto-scaling Group policy 
resource "aws_autoscaling_policy" "ASG_policy" {
  autoscaling_group_name = aws_autoscaling_group.ASG.name
  name = "ASG_policy"
  adjustment_type = "ChangeInCapacity"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}


resource "aws_lb" "flex-lb" {
  name               = "flex-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public-subnet.id, aws_subnet.public-subnet-2.id]
  security_groups = [ aws_security_group.frontend-sg.id ]

  enable_deletion_protection = false

  tags = {
    Name = "flex-lb"
  }
}


resource "aws_lb_target_group" "flex-tg" {
  name        = "flex-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    interval = 30
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 5
    //path = "/indextest.html"
  }
}

resource "aws_lb_listener" "flex-listener" {
  load_balancer_arn = aws_lb.flex-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flex-tg.arn
  }
}

data "aws_route53_zone" "route_53" {
  name         = "emekaweddings.com"
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.route_53.zone_id
  name    = "emekaweddings.com"
  type    = "A"
  alias {
    name = aws_lb.flex-lb.dns_name
    zone_id = aws_lb.flex-lb.zone_id
    evaluate_target_health = false 
  }
}