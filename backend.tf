terraform {
  backend "s3" {
    bucket = "mhdez"
    key    = "terraform/cloudflare.tfstate"
    region = "eu-west-1"
  }
}
