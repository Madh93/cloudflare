variable "cloudflare_api_token" {
  description = "The API Token for operations"
  type        = string
}

variable "cloudflare_account_id" {
  description = "The account ID"
  type        = string
}

variable "domain_name" {
  description = "The domain name"
  type        = string
}

variable "records" {
  description = "The list of records to manage"
  type        = map(map(string))
  default     = {}
}

variable "firewall_rules" {
  description = "The list of firewall rules to apply"
  type        = map(map(string))
  default     = {}
}
