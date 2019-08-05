data "aws_wafregional_web_acl" "waf_acl" {
  name = "${local.namespace}-waf-security-automations"
}

resource "aws_wafregional_regex_pattern_set" "ua_blacklist" {
  count = "${var.ua_blacklist == "true" ? 1 : 0}"
  name  = "${local.namespace}-banned-user-agent-patterns"

  regex_pattern_strings = [
    "[Aa]rachni/",
  ]
}

resource "aws_wafregional_regex_match_set" "ua_blacklist" {
  count = "${var.ua_blacklist == "true" ? 1 : 0}"
  name  = "${local.namespace}-banned-user-agents"

  regex_match_tuple {
    field_to_match {
      data = "User-Agent"
      type = "HEADER"
    }

    regex_pattern_set_id = "${aws_wafregional_regex_pattern_set.ua_blacklist.id}"
    text_transformation  = "NONE"
  }
}

resource "aws_wafregional_rule" "ua_blacklist" {
  count       = "${var.ua_blacklist == "true" ? 1 : 0}"
  name        = "UA Blacklist Rule"
  metric_name = "UABlacklistRule"

  predicate {
    type    = "RegexMatch"
    data_id = "${aws_wafregional_regex_match_set.ua_blacklist.id}"
    negated = false
  }
}

resource "aws_wafregional_byte_match_set" "healthcheck_url" {
  count = "${var.url_blacklist == "true" ? 1 : 0}"
  name  = "${local.namespace}-health-check"

  byte_match_tuples {
    text_transformation   = "NONE"
    target_string         = "Amazon-Route53-Health-Check-Service"
    positional_constraint = "STARTS_WITH"

    field_to_match {
      type = "HEADER"
      data = "user-agent"
    }
  }
}

resource "aws_wafregional_regex_pattern_set" "url_blacklist" {
  count = "${var.url_blacklist == "true" ? 1 : 0}"
  name  = "${local.namespace}-banned-url-patterns"

  regex_pattern_strings = [
    "/wp-(content|admin|json)/",
    "\\.(php|cgi|jsp.?|lnk|bat|com|exe|cmd|ms[ip]|pif|ws[cfh]?)$",
  ]
}

resource "aws_wafregional_regex_match_set" "url_blacklist" {
  count = "${var.url_blacklist == "true" ? 1 : 0}"
  name  = "${local.namespace}-banned-urls"

  regex_match_tuple {
    field_to_match {
      type = "URI"
    }

    regex_pattern_set_id = "${aws_wafregional_regex_pattern_set.url_blacklist.id}"
    text_transformation  = "URL_DECODE"
  }
}

resource "aws_wafregional_rule" "url_blacklist" {
  count       = "${var.url_blacklist == "true" ? 1 : 0}"
  name        = "URL Blacklist Rule"
  metric_name = "URLBlacklistRule"

  predicate {
    type    = "ByteMatch"
    data_id = "${aws_wafregional_byte_match_set.healthcheck_url.id}"
    negated = true
  }

  predicate {
    type    = "RegexMatch"
    data_id = "${aws_wafregional_regex_match_set.url_blacklist.id}"
    negated = false
  }
}

resource "aws_wafregional_ipset" "nul_ips" {
  count = "${var.ip_whitelist == "true" ? 1 : 0}"
  name  = "NUL Internal IP ranges"

  ip_set_descriptor {
    type  = "IPV4"
    value = "10.105.0.0/16"
  }
}

resource "aws_wafregional_rule" "ip_whitelist" {
  count = "${var.ip_whitelist == "true" ? 1 : 0}"
  name  = "${local.namespace}-ip-whitelist"

  predicate {
    type    = "IpMatch"
    data_id = "${aws_wafregional_ipset.nul_ips.id}"
    negated = false
  }
}
