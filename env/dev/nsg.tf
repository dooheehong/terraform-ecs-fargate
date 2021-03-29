resource "aws_security_group" "nsg_lb" {
  name        = "${var.app}-${var.environment}-lb"
  description = "Allow connections from external resources while limiting connections from ${var.app}-${var.environment}-lb to internal resources"
  vpc_id      = aws_vpc.devops-dev.id

  tags = var.tags
}

resource "aws_security_group" "nsg_task" {
  name        = "${var.app}-${var.environment}-task"
  description = "Limit connections from internal resources while allowing ${var.app}-${var.environment}-task to connect to all external resources"
  vpc_id      = aws_vpc.devops-dev.id

  tags = var.tags
}

# Rules for the LB (Targets the task SG)

resource "aws_security_group_rule" "nsg_lb_egress_rule" {
  description              = "Only allow SG ${var.app}-${var.environment}-lb to connect to ${var.app}-${var.environment}-task on port ${var.container_web_port}"
  type                     = "egress"
  from_port                = var.container_web_port
  to_port                  = var.container_web_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nsg_task.id

  security_group_id = aws_security_group.nsg_lb.id
}

resource "aws_security_group_rule" "nsg_lb_egress_rule_socket" {
  description              = "Only allow SG ${var.app}-${var.environment}-lb to connect to ${var.app}-${var.environment}-socket-task on port ${var.container_socket_port}"
  type                     = "egress"
  from_port                = var.container_socket_port
  to_port                  = var.container_socket_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nsg_task.id

  security_group_id = aws_security_group.nsg_lb.id
}

# Rules for the TASK (Targets the LB SG)
resource "aws_security_group_rule" "nsg_task_ingress_rule" {
  description              = "Only allow connections from SG ${var.app}-${var.environment}-lb on port ${var.container_web_port}"
  type                     = "ingress"
  from_port                = var.container_web_port
  to_port                  = var.container_web_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nsg_lb.id

  security_group_id = aws_security_group.nsg_task.id
}

resource "aws_security_group_rule" "nsg_task_ingress_rule_socket" {
  description              = "Only allow connections from SG ${var.app}-${var.environment}-lb on port ${var.container_socket_port}"
  type                     = "ingress"
  from_port                = var.container_socket_port
  to_port                  = var.container_socket_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nsg_lb.id

  security_group_id = aws_security_group.nsg_task.id
}

resource "aws_security_group_rule" "nsg_task_egress_rule" {
  description = "Allows task to establish connections to all resources"
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nsg_task.id
}

# Group and rules for Elasticache, SQS, and RDS Aurora
resource "aws_security_group" "devops-dev-db" {
  vpc_id = aws_vpc.devops-dev.id
  name = "devops_dev_intra"
  description = "devops Dev Intra Security Group"

  tags = {
    Name = "devops Dev Intra Security Group"
    Description = ""
  }
}

resource "aws_security_group_rule" "devops-dev-intra-db-all-from-nsg_task" {
  description = "Allow all connections from nsg_task"
  type = "ingress"
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  source_security_group_id = aws_security_group.nsg_task.id

  security_group_id = aws_security_group.devops-dev-db.id
}

resource "aws_security_group_rule" "devops-dev-intra-db-all-from-bastions" {
  description = "Allow all connections from bastions"
  type = "ingress"
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  source_security_group_id = aws_security_group.devops-dev-bastion.id

  security_group_id = aws_security_group.devops-dev-db.id
}

resource "aws_security_group_rule" "devops-dev-intra-db-egress" {
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.devops-dev-db.id
}

# For bastions
resource "aws_security_group" "devops-dev-bastion" {
  vpc_id = aws_vpc.devops-dev.id
  name = "devops_dev_bastion"
  description = "devops Dev Bastion Security Group"

  tags = {
    Name = "devops Dev Bastion Security Group"
    Description = ""
  }
}

resource "aws_security_group_rule" "devops-dev-bastion-ssh-from-all" {
  description = "Allow all SSH connections"
  type = "ingress"
  from_port = "22"
  to_port = "22"
  protocol = "TCP"
  cidr_blocks = var.allowed_management_cidr_blocks

  security_group_id = aws_security_group.devops-dev-bastion.id
}

resource "aws_security_group_rule" "devops-dev-bastion-wg-tcp-from-all" {
  description = "Allow WG connections"
  type = "ingress"
  from_port = "51820"
  to_port = "51820"
  protocol = "TCP"
  cidr_blocks = var.allowed_management_cidr_blocks

  security_group_id = aws_security_group.devops-dev-bastion.id
}

resource "aws_security_group_rule" "devops-dev-bastion-wg-from-all" {
  description = "Allow WG connections"
  type = "ingress"
  from_port = "51820"
  to_port = "51820"
  protocol = "UDP"
  cidr_blocks = var.allowed_management_cidr_blocks

  security_group_id = aws_security_group.devops-dev-bastion.id
}

resource "aws_security_group_rule" "devops-dev-bastion-egress" {
  type        = "egress"
  from_port   = "-1"
  to_port     = "-1"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.devops-dev-bastion.id
}
