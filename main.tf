terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

// TOPOLOGÍA DE RED

# Creamos la VPC.
resource "aws_vpc" "vpc" {
  cidr_block                       = "10.0.0.0/16"
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = false
  enable_dns_hostnames             = true
  enable_dns_support               = true
  tags = {
    Name = var.resource_names.vpc
  }
}

# Subnet public A, eu-west-1a.
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = var.resource_names.subnets.public_a
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Subnet public B, eu-west-1b.
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = var.resource_names.subnets.public_b
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Internet Gateway (habilita el tráfico de la zona pública a internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.resource_names.igw
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Route Table (enruta el tráfico de la zona pública)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = var.resource_names.route_tables.public
  }
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]
}

# Subnet public A ---> Route Table
resource "aws_route_table_association" "public_route_table_associations_1" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
  depends_on = [
    aws_subnet.public_subnet_a,
    aws_route_table.public_route_table
  ]
}

# Subnet public B ---> Route Table
resource "aws_route_table_association" "public_route_table_associations_2" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
  depends_on = [
    aws_subnet.public_subnet_b,
    aws_route_table.public_route_table
  ]
}

# Elastic IP para el NAT Gateway.
resource "aws_eip" "natgw_eip" {
  vpc              = true
  public_ipv4_pool = "amazon"
  tags = {
    Name = var.resource_names.eip
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# NAT Gateway para poder dar acceso a internet a la zona private
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = var.resource_names.natgw
  }
  depends_on = [
    aws_vpc.vpc,
    aws_subnet.public_subnet_a,
    aws_eip.natgw_eip
  ]
}

# Subnet private A, eu-west-1a.
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = var.resource_names.subnets.private_a
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Subnet private B, eu-west-1b.
resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = var.resource_names.subnets.private_b
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Route Table (enruta el tráfico de la zona privada)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = var.resource_names.route_tables.private
  }
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.natgw
  ]
}

# Subnet private A ---> Route Table
resource "aws_route_table_association" "private_route_table_associations_1" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
  depends_on = [
    aws_subnet.private_subnet_a,
    aws_route_table.private_route_table
  ]
}

# Subnet private B ---> Route Table
resource "aws_route_table_association" "private_route_table_associations_2" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
  depends_on = [
    aws_subnet.private_subnet_b,
    aws_route_table.private_route_table
  ]
}


// SECURITY GROUPS

# Security Group de la base de datos
resource "aws_security_group" "security_group_ddbb" {
  name   = var.resource_names.security_groups.ddbb
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.resource_names.security_groups.ddbb
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Security Group de la Webapp 
resource "aws_security_group" "security_group_webapp" {
  name   = var.resource_names.security_groups.webapp
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.resource_names.security_groups.webapp
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Security Group del Load Balancer
resource "aws_security_group" "security_group_balancer" {
  name   = var.resource_names.security_groups.balancer
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.resource_names.security_groups.balancer
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Security Group del Bastion Host 
resource "aws_security_group" "security_group_bastion" {
  name   = var.resource_names.security_groups.bastion
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.resource_names.security_groups.bastion
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Habilitamos las peticiones entrantes de la base de datos a la Webapp en el puerto TCP 3306
resource "aws_security_group_rule" "security_group_rule_1" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_webapp.id
  description              = "Acceso a instancias Webapp"
  security_group_id        = aws_security_group.security_group_ddbb.id
  depends_on = [
    aws_security_group.security_group_webapp,
    aws_security_group.security_group_ddbb
  ]
}

# Habilitamos las peticiones salientes de la Webapp a la base de datos en el puerto TCP 3306
resource "aws_security_group_rule" "security_group_rule_2" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_ddbb.id
  description              = "Acceso a la base de datos Webapp"
  security_group_id        = aws_security_group.security_group_webapp.id
  depends_on = [
    aws_security_group.security_group_webapp,
    aws_security_group.security_group_ddbb
  ]
}

# Habilitamos el tráfico de salida de la Webapp a internet
resource "aws_security_group_rule" "security_group_rule_3" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  description       = "Acceso a Internet"
  security_group_id = aws_security_group.security_group_webapp.id
  depends_on = [
    aws_security_group.security_group_webapp
  ]
}

# Habilitamos las peticiones de entrantes Webapp  <--- Balanceador de Carga en el puerto TCP 8080
resource "aws_security_group_rule" "security_group_rule_4" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_balancer.id
  description              = "Acceso al balanceador Webapp"
  security_group_id        = aws_security_group.security_group_webapp.id
  depends_on = [
    aws_security_group.security_group_webapp,
    aws_security_group.security_group_balancer
  ]
}

# Habilitamos las peticiones salientes Balanceador de carga ---> Webapp en el puerto TCP 8080
resource "aws_security_group_rule" "security_group_rule_5" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_webapp.id
  description              = "Acceso a instancias Webapp"
  security_group_id        = aws_security_group.security_group_balancer.id
  depends_on = [
    aws_security_group.security_group_webapp,
    aws_security_group.security_group_balancer
  ]
}

# Habilitamos las peticiones entrantes Balanceador de carga <--- Internet, puerto TCP 80
resource "aws_security_group_rule" "security_group_rule_6" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  description       = "Webapp acceso publico"
  security_group_id = aws_security_group.security_group_balancer.id
  depends_on = [
    aws_security_group.security_group_balancer
  ]
}

# Habilitamos las peticiones entrantes Bastion Host  <--- Internet, puerto TCP 3389
resource "aws_security_group_rule" "security_group_rule_7" {
  type      = "ingress"
  from_port = 3389
  to_port   = 3389
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  description       = "RDP acceso publico"
  security_group_id = aws_security_group.security_group_bastion.id
  depends_on = [
    aws_security_group.security_group_bastion
  ]
}

# Habilitamos el tráfico saliente Bastion Host ---> Internet
resource "aws_security_group_rule" "security_group_rule_8" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  description       = "Acceso a Internet"
  security_group_id = aws_security_group.security_group_bastion.id
  depends_on = [
    aws_security_group.security_group_bastion
  ]
}

// BASE DE DATOS (MySQL)

# Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = var.resource_names.subnet_group
  description = "Grupo de subnet de la base de datos Webapp"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]
  tags = {
    Name = var.resource_names.subnet_group
  }
  depends_on = [
    aws_subnet.private_subnet_a,
    aws_subnet.private_subnet_b
  ]
}

# Instancia MySQL
resource "aws_db_instance" "rds_instance" {
  engine                              = "MySQL"
  engine_version                      = "8.0.17"
  identifier                          = var.resource_names.rds_instance
  port                                = 3306
  name                                = var.database.dbname
  username                            = var.database.username
  password                            = var.database.password
  iam_database_authentication_enabled = false
  instance_class                      = "db.t2.micro"
  allocated_storage                   = 20
  storage_type                        = "gp2"
  storage_encrypted                   = false
  max_allocated_storage               = 0
  db_subnet_group_name                = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible                 = true
  vpc_security_group_ids = [
    aws_security_group.security_group_ddbb.id
  ]
  apply_immediately            = true
  multi_az                     = false
  allow_major_version_upgrade  = false
  auto_minor_version_upgrade   = false
  deletion_protection          = false
  skip_final_snapshot          = true
  performance_insights_enabled = false
  backup_retention_period      = 0
  depends_on = [
    aws_db_subnet_group.rds_subnet_group
  ]
}

# Secret
resource "aws_secretsmanager_secret" "db_conn_secret" {
  name        = var.resource_names.secret
  description = "Secreto conexion base de datos Webapp"
  tags = {
    Name = var.resource_names.secret
  }
  depends_on = [
    aws_db_instance.rds_instance
  ]
}

# Guardamos las credenciales de conexión en el secreto
resource "aws_secretsmanager_secret_version" "db_conn_secret_value" {
  secret_id = aws_secretsmanager_secret.db_conn_secret.id
  secret_string = jsonencode({
    "host" : aws_db_instance.rds_instance.address,
    "db" : var.database.dbname,
    "username" : var.database.username,
    "password" : var.database.password
  })
  depends_on = [
    aws_secretsmanager_secret.db_conn_secret
  ]
}

// IAM

# Contenido de la política de seguridad
data "aws_iam_policy_document" "secrets_manager_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.db_conn_secret.arn
    ]
  }

  depends_on = [
    aws_secretsmanager_secret.db_conn_secret
  ]
}

# Política de seguridad con el contenido previo
resource "aws_iam_policy" "db_conn_policy" {
  name        = var.resource_names.policy
  description = "Recuperacion confg base de datos Webapp"
  policy      = data.aws_iam_policy_document.secrets_manager_policy.json
}

# Contenido del rol.
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

# Rol con el contenido previo
resource "aws_iam_role" "db_conn_role" {
  name               = var.resource_names.role
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name = var.resource_names.role
  }
}

# Asociamos política de seguridad al rol
resource "aws_iam_policy_attachment" "db_conn_policy_role_assoc" {
  name = "db_conn"
  roles = [
    aws_iam_role.db_conn_role.id
  ]
  policy_arn = aws_iam_policy.db_conn_policy.arn
  depends_on = [
    aws_iam_role.db_conn_role,
    aws_iam_policy.db_conn_policy
  ]
}

// WEBAPP CON EC2

# Perfil para asignar el rol previamente creado a las instancias
resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.resource_names.profile
  role = aws_iam_role.db_conn_role.id
  depends_on = [
    aws_iam_policy_attachment.db_conn_policy_role_assoc
  ]
}

# KeyPair a partir de la clave pública de nuestro certificado local
resource "aws_key_pair" "key_pair" {
  key_name   = var.resource_names.key_pair
  public_key = file("./${var.resource_names.key_pair}.pub")
}

# Plantilla con la configuración instancias EC2.
resource "aws_launch_template" "webapp_vm" {
  name                    = var.resource_names.template
  image_id                = "ami-06ce3edf0cff21f07"
  instance_type           = "t2.micro"
  key_name                = aws_key_pair.key_pair.key_name
  disable_api_termination = false
  user_data               = filebase64("./bootstrap.sh")
  network_interfaces {
    associate_public_ip_address = false
    security_groups = [
      aws_security_group.security_group_webapp.id
    ]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  tags = {
    Name = var.resource_names.template
  }
  depends_on = [
    aws_security_group.security_group_webapp,
    aws_iam_instance_profile.ec2_profile,
    aws_key_pair.key_pair
  ]
}

# Grupo de auto escalado.
resource "aws_autoscaling_group" "webapp_asg" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2
  vpc_zone_identifier = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]
  launch_template {
    id      = aws_launch_template.webapp_vm.id
    version = "$Latest"
  }
  target_group_arns = [
    aws_lb_target_group.webapp_tg.arn
  ]
  tag {
    key                 = "Name"
    value               = var.resource_names.autoscaling_group
    propagate_at_launch = true
  }
  depends_on = [
    aws_subnet.private_subnet_a,
    aws_subnet.private_subnet_b,
    aws_launch_template.webapp_vm,
    aws_lb_target_group.webapp_tg
  ]
}

// BALANCEADOR DE CARGA

# Balanceador de carga para exponer Webapp públicamente
resource "aws_lb" "webapp_alb" {
  name               = var.resource_names.load_balancer
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.security_group_balancer.id
  ]
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id
  ]
  depends_on = [
    aws_subnet.public_subnet_a,
    aws_subnet.public_subnet_b,
    aws_security_group.security_group_balancer
  ]
}

# Target Group que configura la Webapp como destino del tráfico entrante del balanceador de carga
resource "aws_lb_target_group" "webapp_tg" {
  name        = var.resource_names.target_group
  target_type = "instance"
  protocol    = "HTTP"
  port        = 8080
  vpc_id      = aws_vpc.vpc.id
  health_check {
    protocol            = "HTTP"
    path                = "/api/utils/healthcheck"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 5
    matcher             = "200"
  }
  depends_on = [
    aws_lb.webapp_alb
  ]
}

# Listener que redirige el tráfico Internet a la Webapp.
resource "aws_lb_listener" "webapp_alb_listener" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }
  depends_on = [
    aws_lb.webapp_alb,
    aws_lb_target_group.webapp_tg
  ]
}

// DOMINIO "awspractica"

# Dominio awspractica.com como Hosted Zone privada
resource "aws_route53_zone" "awspractica" {
  name = "awspractica.com"
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

# Record A para asociar el subdominio aws.awspractica.com al DNS del Balanceador de carga
resource "aws_route53_record" "aws" {
  zone_id = aws_route53_zone.awspractica.zone_id
  name    = "aws.awspractica.com"
  type    = "A"
  alias {
    name                   = aws_lb.webapp_alb.dns_name
    zone_id                = aws_lb.webapp_alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [
    aws_route53_zone.awspractica,
    aws_lb.webapp_alb
  ]
}

// BASTION HOST

# Instancia en EC2.
resource "aws_instance" "bastion" {
  ami                         = "ami-0c95efaa8fa6e2424"
  instance_type               = "t2.large"
  subnet_id                   = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [
    aws_security_group.security_group_bastion.id
  ]
  disable_api_termination = false
  monitoring              = false
  tags = {
    Name = var.resource_names.bastion
  }
  depends_on = [
    aws_subnet.public_subnet_a,
    aws_security_group.security_group_bastion,
    aws_key_pair.key_pair
  ]
}
