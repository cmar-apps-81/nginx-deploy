resource "aws_security_group" "alb" {
  name        = "alb"
  description = "Security Group for ALB"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name                       = "alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  tags = {
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "alb_http" {
  name     = "alb-http"
  vpc_id   = module.vpc.vpc_id
  port     = 31647
  protocol = "HTTP"
  health_check {
    path                = "/"
    port                = var.target_group_port
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 4
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.alb_http.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "alb_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = module.acm.this_acm_certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.alb_http.arn
    type             = "forward"
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name               = "cmar.pt"
  subject_alternative_names = ["*.cmar.pt"]

  validate_certificate = false

  tags = {
    Name = "cmar.pt"
  }
}
