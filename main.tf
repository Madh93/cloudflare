provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

########
# Zone #
########

resource "cloudflare_zone" "default" {
  account_id = var.cloudflare_account_id
  zone       = var.domain_name
}

resource "cloudflare_zone_settings_override" "default" {
  zone_id = cloudflare_zone.default.id

  settings {
    ssl = "full"
  }
}

###############
# DNS Records #
###############

resource "cloudflare_record" "default" {
  for_each = var.records

  zone_id = cloudflare_zone.default.id
  type    = each.value.type
  name    = each.value.name
  value   = each.value.content
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

  dynamic "rules" {
    for_each = var.firewall_rules
    content {
      action      = lookup(rules.value, "action", "block")
      expression  = rules.value.expression
      description = lookup(rules.value, "description", "")
      enabled     = true
    }
  }
}

###################
# Transform Rules #
###################

resource "cloudflare_ruleset" "extra_security_headers" {
  zone_id = cloudflare_zone.default.id
  name    = "default"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules {
    description = "Extra Security Headers"
    action      = "rewrite"
    expression  = "(ssl)"
    enabled     = true
    action_parameters {
      headers {
        name      = "Permissions-Policy"
        operation = "set"
        value     = "camera=(),microphone=(),usb=()"
      }
      headers {
        name      = "Strict-Transport-Security"
        operation = "set"
        value     = "max-age=31536000; includeSubDomains"
      }
    }
  }
}
