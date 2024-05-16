# Availability Zones
data "aws_availability_zones" "azs" {
  state = "available"
}