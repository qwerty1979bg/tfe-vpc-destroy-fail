###################################################################
# Outputs
###################################################################

output "igw_id" {
  value = "${aws_internet_gateway.this.id}"
}

output "vpc_id" {
  value = "${aws_vpc.this.id}"
}

output "random_net" {
  value = "${random_id.this.hex}"
}

// Private Networks
// ----------------------------------------------------------------

output "private_route_table_ids" {
  value = ["${aws_route_table.private.*.id}"]
}

output "private_subnet_count" {
  value = "${aws_subnet.private.count}"
}

output "private_subnets" {
  value = ["${aws_subnet.private.*.cidr_block}"]
}

output "private_subnet_ids" {
  value = ["${aws_subnet.private.*.id}"]
}

// Data Networks
// ----------------------------------------------------------------

output "data_route_table_ids" {
  value = ["${aws_route_table.data.*.id}"]
}

output "data_subnet_count" {
  value = "${aws_subnet.data.count}"
}

output "data_subnets" {
  value = ["${aws_subnet.data.*.cidr_block}"]
}

output "data_subnet_ids" {
  value = ["${aws_subnet.data.*.id}"]
}

// Public Networks
// ----------------------------------------------------------------

output "public_route_table_ids" {
  value = ["${aws_route_table.public.*.id}"]
}

output "public_subnet_count" {
  value = "${aws_subnet.public.count}"
}

output "public_subnets" {
  value = ["${aws_subnet.public.*.cidr_block}"]
}

output "public_subnet_ids" {
  value = ["${aws_subnet.public.*.id}"]
}
