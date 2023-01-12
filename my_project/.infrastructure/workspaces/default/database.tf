locals {
  rds_db_port = var.rds_db_port == null ? 5432 : var.rds_db_port
}

# Create a random password
resource "random_password" "db_password" {
  length  = 16
  special = true
  numeric = true
  upper   = true
  lower   = true
}

# Create a security group for the RDS instance
resource "aws_security_group" "db" {
  name        = "${local.name}-db"
  description = "RDS security group"
  vpc_id      = module.vpc.vpc_id

  # Allow access from the app
  ingress {
    from_port       = local.rds_db_port
    to_port         = local.rds_db_port
    security_groups = [aws_security_group.app.id]
    protocol        = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create RDS subnet group
resource "aws_db_subnet_group" "db" {
  name       = "${local.name}-rds-database"
  subnet_ids = module.vpc.private_subnets
}

# Create RDS instance
resource "aws_db_instance" "db" {
  identifier              = "${local.name}-database"
  username                = var.rds_db_username
  password                = random_password.db_password.result
  db_name                 = replace(local.name, "-", "_")
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "14.5"
  port                    = local.rds_db_port
  instance_class          = var.rds_instance_type
  backup_retention_period = 7
  publicly_accessible     = false
  storage_encrypted       = var.rds_encrypt_at_rest
  multi_az                = false
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  skip_final_snapshot     = true
}