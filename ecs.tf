# use existing VPCs and subnets that already exist. 
# note: in a production environment, we'd manage our own topologies.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

# Use an open source module that has already predefined the resources for creating an alb
module "alb" {
  source  = "umotif-public/alb/aws"
  version = "~> 2.0"

  name_prefix        = "alb-non-negative-integer"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = data.aws_vpc.default.id
  subnets            = data.aws_subnet_ids.all.ids
}

# Create LB listenders for the ALB
resource "aws_lb_listener" "alb_listen_port_80" {
  load_balancer_arn = module.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.ecs-fargate.target_group_arn[0]
  }
}

# Create Security Groups to ALLOW ALL access
resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = module.alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# Give the ALB access to the ECS task in port 80
resource "aws_security_group_rule" "task_ingress_80" {
  security_group_id        = module.ecs-fargate.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = module.alb.security_group_id
}

# Create ECS cluster with fargate spot instances

resource "aws_ecs_cluster" "cluster" {
  name = "non-negative-ecs-clustr"

  capacity_providers = ["FARGATE_SPOT"]
  
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# Use an open source fargate module that has all the resources predefined e.g. IAM roles, creation of ECS tasks etc.
module "ecs-fargate" {
  source = "umotif-public/ecs-fargate/aws"
  version = "~> 6.1.0"

  name_prefix = "non-negative"
  vpc_id             = data.aws_vpc.default.id
  private_subnet_ids = data.aws_subnet_ids.all.ids
  cluster_id = aws_ecs_cluster.cluster.id
  task_container_image   = "zeemarsh/non-negative-integer:0.0.1"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = true

  target_groups = [
    {
      target_group_name = "non-negative-integer"
      container_port    = 80
    }
  ]

  # Health check endpoint is defined on / and just returns 200
  health_check = {
    port = "traffic-port"
    path = "/"
  }

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT",
      weight            = 100
    }
  ]
}
