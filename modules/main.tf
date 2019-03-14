###################################################################
# Get Environment Info
###################################################################

data "aws_availability_zones" "available" {}

###################################################################
# Random ID Generation Resource (Tags and Labels)
###################################################################

// TODO - Review if this is needed here or in the core module.
resource "random_id" "this" {
  byte_length = 3
}

###################################################################
# DHCP Options
###################################################################

resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = "${merge(var.tags, map("content_type", var.content_type), map("environment", var.environment), map("app_type", var.app_type), map("tenant_id", var.tenant_id))}"
}

###################################################################
# VPC
###################################################################

resource "aws_vpc" "this" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = "${var.vpc_cidr_block}"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-%s", var.tenant_id, var.environment, var.app_type, var.content_type, random_id.this.hex),
        "app_type", var.app_type,
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

###################################################################
# Internet Gateway
###################################################################

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-%s", var.tenant_id, var.environment, var.app_type, var.content_type, random_id.this.hex),
        "app_type", var.app_type,
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

###################################################################
# DHCP Option Association
###################################################################

resource "aws_vpc_dhcp_options_association" "dhcp_options_association" {
  vpc_id          = "${aws_vpc.this.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dhcp_options.id}"
}

###################################################################
# NAT Gateway
###################################################################

resource "aws_eip" "nat_eip" {
  count = "${var.enable_nat_gateway == 1 ? length(var.public_subnets) : 0}"

  vpc = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = "${element(aws_eip.nat_eip.*.id, count.index)}"

  count = "${var.enable_nat_gateway == 1 ? length(var.public_subnets) : 0}"

  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-data-%s-%s", var.tenant_id, var.environment, var.app_type, var.content_type, element(data.aws_availability_zones.available.names, count.index), random_id.this.hex),
        "app_type", var.app_type,
        "availability_zone", element(data.aws_availability_zones.available.names, count.index),
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

###################################################################
# Network - Private
###################################################################

resource "aws_route_table" "private" {
  count  = "${length(var.private_subnets)}"
  vpc_id = "${aws_vpc.this.id}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-private-%s", var.tenant_id, var.environment, var.app_type, var.content_type, random_id.this.hex),
        "app_type", var.app_type,
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

resource "aws_route" "private_igw" {
  count = "${var.enable_nat_gateway == 0 ? (length(var.private_subnets)) : 0}"

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"
  route_table_id         = "${(element(aws_route_table.private.*.id, count.index))}"
}

resource "aws_route" "private_ngw" {
  count = "${var.enable_nat_gateway == 1 ? (length(var.private_subnets)) : 0}"

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.this.*.id, count.index)}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_subnet" "private" {
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "${var.private_subnets[count.index]}"
  count             = "${length(var.private_subnets)}"

  map_public_ip_on_launch = "${var.enable_nat_gateway == 1 ? false : true}"

  vpc_id = "${aws_vpc.this.id}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-private-%s-%s", var.tenant_id, var.environment, var.app_type, var.content_type, element(data.aws_availability_zones.available.names, count.index), random_id.this.hex),
        "app_type", var.app_type,
        "availability_zone", element(data.aws_availability_zones.available.names, count.index),
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
}

###################################################################
# Network - Data
###################################################################

resource "aws_route_table" "data" {
  count  = "${length(var.data_subnets) >= 1 ? 1 : 0}"
  vpc_id = "${aws_vpc.this.id}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-data-%s", var.tenant_id, var.environment, var.app_type, var.content_type, random_id.this.hex),
        "app_type", var.app_type,
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

resource "aws_route" "data_igw_route" {
  count                  = "${length(var.data_subnets) >= 1 ? 1 : 0}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"
  route_table_id         = "${element(aws_route_table.data.*.id, count.index)}"
}

resource "aws_subnet" "data" {
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block              = "${var.data_subnets[count.index]}"
  count                   = "${length(var.data_subnets)}"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.this.id}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-data-%s-%s", var.tenant_id, var.environment, var.app_type, var.content_type, element(data.aws_availability_zones.available.names, count.index), random_id.this.hex),
        "app_type", var.app_type,
        "availability_zone", element(data.aws_availability_zones.available.names, count.index),
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

resource "aws_route_table_association" "data" {
  count          = "${length(var.data_subnets)}"
  route_table_id = "${element(aws_route_table.data.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.data.*.id, count.index)}"
}

###################################################################
# Network - Public
###################################################################

resource "aws_route_table" "public" {
  count  = "${length(var.public_subnets) >= 1 ? 1 : 0}"
  vpc_id = "${aws_vpc.this.id}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-public-%s", var.tenant_id, var.environment, var.app_type, var.content_type, random_id.this.hex),
        "app_type", var.app_type,
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

resource "aws_route" "public_igw_route" {
  count                  = "${length(var.public_subnets) >= 1 ? 1 : 0}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"
  route_table_id         = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public" {
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "${var.public_subnets[count.index]}"
  count             = "${length(var.public_subnets)}"

  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.this.id}"

  tags = "${
    merge(
      var.tags,
      map(
        "Name", format("aws-%s-%s-%s-%s-public-%s-%s", var.tenant_id, var.environment, var.app_type, var.content_type, element(data.aws_availability_zones.available.names, count.index), random_id.this.hex),
        "app_type", var.app_type,
        "availability_zone", element(data.aws_availability_zones.available.names, count.index),
        "content_type", var.content_type,
        "environment", var.environment,
        "tenant_id", var.tenant_id
      )
    )
  }"
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}
