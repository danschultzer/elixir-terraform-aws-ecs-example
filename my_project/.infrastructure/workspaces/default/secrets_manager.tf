resource "aws_secretsmanager_secret" "release_cookie" {
  name                    = "${local.name}-release-cookie"
  description             = "The release cookie for nodes to connect"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "release_cookie" {
  secret_id     = aws_secretsmanager_secret.release_cookie.id
  secret_string = random_password.release_cookie.result
}

resource "aws_secretsmanager_secret" "secret_key_base" {
  name                    = "${local.name}-phoenix-secret-key-base"
  description             = "Secret key base for Phoenix apps"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "secret_key_base" {
  secret_id     = aws_secretsmanager_secret.secret_key_base.id
  secret_string = random_password.secret_key_base.result
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.name}-db-credentials"
  description             = "Database credentials"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  # This format is necessary for password rotation:
  # https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html
  secret_string = jsonencode({
    engine   = aws_db_instance.db.engine
    host     = aws_db_instance.db.address
    username = var.rds_db_username
    password = random_password.db_password.result
    dbname   = aws_db_instance.db.db_name
    port     = aws_db_instance.db.port
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = module.vpc.private_subnets

  tags = {
    Name = "secretsmanager-endpoint"
  }
}