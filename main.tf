provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

########
# Zone #
########

resource "cloudflare_zone" "default" {
  account = {
    id = var.cloudflare_account_id
  }
  name = var.domain_name
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = cloudflare_zone.default.id
  setting_id = "ssl"
  value      = "full"
}

###############
# DNS Records #
###############

resource "cloudflare_dns_record" "default" {
  for_each = var.records

  zone_id = cloudflare_zone.default.id
  type    = each.value.type
  name    = each.key
  content = each.value.content
  comment = lookup(each.value, "comment", null)
  proxied = lookup(each.value, "proxied", true)
  ttl     = lookup(each.value, "ttl", 1)
}

####################
# WAF Custom Rules #
####################

resource "cloudflare_ruleset" "waf_custom_rules" {
  zone_id = cloudflare_zone.default.id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [
    for rule in var.firewall_rules : {
      action      = lookup(rule, "action", "block")
      expression  = rule.expression
      description = lookup(rule, "description", "")
      enabled     = true
    }
  ]
}

###################
# Transform Rules #
###################

resource "cloudflare_ruleset" "extra_security_headers" {
  zone_id = cloudflare_zone.default.id
  name    = "default"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules = [
    {
      description = "Extra Security Headers"
      action      = "rewrite"
      expression  = "(ssl)"
      enabled     = true
      action_parameters = {
        headers = {
          "Permissions-Policy" = {
            operation = "set"
            value     = "camera=(),microphone=(),usb=()"
          },
          "Strict-Transport-Security" = {
            operation = "set"
            value     = "max-age=31536000; includeSubDomains"
          }
        }
      }
    }
  ]
}
