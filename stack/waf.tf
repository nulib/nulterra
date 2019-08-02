data "aws_wafregional_web_acl" "waf_acl" {
  name = "${local.namespace}-waf-security-automations"
}

resource "aws_wafregional_regex_pattern_set" "ua_blacklist" {
  name = "${local.namespace}-banned-user-agent-patterns"

  regex_pattern_strings = [
    "[Aa]rachni/",
  ]
}

resource "aws_wafregional_regex_match_set" "ua_blacklist" {
  name = "${local.namespace}-banned-user-agents"

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
  name        = "UA Blacklist Rule"
  metric_name = "UABlacklistRule"

  predicate {
    type    = "RegexMatch"
    data_id = "${aws_wafregional_regex_match_set.ua_blacklist.id}"
    negated = false
  }
}

resource "aws_wafregional_regex_pattern_set" "url_blacklist" {
  name = "${local.namespace}-banned-url-patterns"

  regex_pattern_strings = [
    "/wp-(content|admin|json)/",
    "\\.(php|cgi|jsp.?|lnk|bat|com|exe|cmd|ms[ip]|pif|ws[cfh]?)$",
  ]
}

resource "aws_wafregional_regex_match_set" "url_blacklist" {
  name = "${local.namespace}-banned-urls"

  regex_match_tuple {
    field_to_match {
      type = "URI"
    }

    regex_pattern_set_id = "${aws_wafregional_regex_pattern_set.url_blacklist.id}"
    text_transformation  = "URL_DECODE"
  }
}

resource "aws_wafregional_rule" "url_blacklist" {
  name        = "URL Blacklist Rule"
  metric_name = "URLBlacklistRule"

  predicate {
    type    = "RegexMatch"
    data_id = "${aws_wafregional_regex_match_set.url_blacklist.id}"
    negated = false
  }
}
