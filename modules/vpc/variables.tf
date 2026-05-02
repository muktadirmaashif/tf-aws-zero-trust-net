variable "vpc_cidr" {
  description = "VPC main cidr block"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid IPv4 Block"
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

# variable "subnet_map" {
#   description = "subnets to be mapped"
#   type        = map(string)
# }

