
# Recursos
variable "resource_names" {
  type = object({
    vpc               = string
    eip               = string
    natgw             = string
    igw               = string
    route_tables      = map(string)
    subnets           = map(string)
    security_groups   = map(string)
    subnet_group      = string
    rds_instance      = string
    secret            = string
    policy            = string
    role              = string
    profile           = string
    key_pair          = string
    template          = string
    autoscaling_group = string
    bastion           = string
    target_group      = string
    load_balancer     = string
  })
  default = {
    vpc   = "practica-aws-vpc"
    eip   = "practica-aws-nat-gw-eip"
    natgw = "practica-aws-nat-gw"
    igw   = "practica-aws-igw"
    route_tables = {
      private = "practica-aws-private-rt"
      public  = "practica-aws-public-rt"
    }
    subnets = {
      private_a = "practica-aws-private-subnet-a"
      private_b = "practica-aws-private-subnet-b"
      public_a  = "practica-aws-public-subnet-a"
      public_b  = "practica-aws-public-subnet-b"
    }
    security_groups = {
      webapp   = "practica-aws-webapp-sg"
      ddbb     = "practica-aws-ddbb-sg"
      balancer = "practica-aws-balancer-sg"
      bastion  = "practica-aws-bastion-sg"
    }
    subnet_group      = "practica-aws-mysql-sg"
    rds_instance      = "practica-aws-mysql-rds"
    secret            = "rtb-db-secret"
    policy            = "practica-aws-rtb-sm-policy"
    role              = "practica-aws-ec2-role"
    profile           = "practica-aws-ec2-profile"
    key_pair          = "practica-aws-ec2-kp"
    template          = "practica-aws-webapp-vm"
    autoscaling_group = "practica-aws-webapp-asg"
    bastion           = "practica-aws-bastion"
    target_group      = "practica-aws-webapp-tg"
    load_balancer     = "practica-aws-webapp-alb"
  }
}

# Base de datos.
variable "database" {
  type = object({
    dbname   = string
    username = string
    password = string
  })
  default = {
    dbname   = "remember_the_bread"
    username = "rtb_user"
    password = "rtb-pass-1$"
  }
}