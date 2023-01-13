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

##################
# Firewall Rules #
##################

resource "cloudflare_filter" "default" {
  for_each = var.firewall_rules

  zone_id    = cloudflare_zone.default.id
  expression = each.value.expression
}

resource "cloudflare_firewall_rule" "default" {
  for_each = var.firewall_rules

  zone_id     = cloudflare_zone.default.id
  filter_id   = cloudflare_filter.default[each.key].id
  description = lookup(each.value, "description", "")
  action      = lookup(each.value, "action", "block")
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
