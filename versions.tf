terraform {
  required_version = "~> 1.3"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.32.0"
    }
  }
}
