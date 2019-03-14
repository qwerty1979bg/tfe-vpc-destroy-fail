###################################################################
# Network Module
###################################################################

module "demo_network" {
  //source = "git::ssh://git@bitbucket.org/thinkwrap/terraform-aws-vpc//modules?ref=master"
  source = "./modules"

  app_type     = "vpc-net"
  content_type = "node"
  environment  = "sysdemo"
  tenant_id    = "000000"

  // Module
  vpc_cidr_block = "10.0.0.0/20"

  // TODO - Assumes prod; map this pattern out better.
  public_subnets = [
    "${cidrsubnet("10.0.0.0/20", 6,16)}",
    "${cidrsubnet("10.0.0.0/20", 6,17)}",
  ]

  data_subnets = [
    "${cidrsubnet("10.0.0.0/20", 7,0)}",
    "${cidrsubnet("10.0.0.0/20", 7,1)}",
  ]

  private_subnets = [
    "${cidrsubnet("10.0.0.0/20", 4,8)}",
    "${cidrsubnet("10.0.0.0/20", 4,9)}",
  ]

  ###################################################################
  # NAT Gateway
  ###################################################################

  enable_nat_gateway = false

}