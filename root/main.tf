terraform {

  backend "s3" {
    bucket       = "remote-state-533267297111"
    region       = "us-east-1"
    key          = "zero-trust-net/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}


module "vpc" {
  source      = "../modules/vpc"
  common_tags = var.common_tags
}
