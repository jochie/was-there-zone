# https://www.terraform.io/docs/providers/aws/r/s3_bucket_object.html

locals {
  smtp_server = "smtp.is-here.com"
  mx_server = "35.162.153.74"
  target = "was-there.statichost.eu"
}

# Get A and AAAA lookups of the 'target' hostname

data "dns_a_record_set" "domain-a" {
  host = local.target
}

data "dns_aaaa_record_set" "domain-aaaa" {
  host = local.target
}

# Define the zone

resource "desec_domain" "domain" {
  name = "was-there.com"
}

# Can't use CNAME at zone apex, so we add A and AAAA records for the
# target instead

resource "desec_rrset" "main-a" {
  domain = desec_domain.domain.name
  subname = ""
  type = "A"
  records = data.dns_a_record_set.domain-a.addrs
  ttl = 3600
}

resource "desec_rrset" "main-aaaa" {
  domain = desec_domain.domain.name
  subname = ""
  type = "AAAA"
  records = data.dns_aaaa_record_set.domain-aaaa.addrs
  ttl = 3600
}

# For www.* we use a simpler CNAME

resource "desec_rrset" "www-cname" {
  domain = desec_domain.domain.name
  subname = "www"
  type = "CNAME"
  records = [ "${local.target}." ]
  ttl = 3600
}

# Where should email be delivered

resource "desec_rrset" "main-mx" {
  domain = desec_domain.domain.name
  subname = ""
  type = "MX"
  records = [ "10 ${local.smtp_server}." ]
  ttl = 3600
}

# From where is email allowed to be sent

resource "desec_rrset" "main-spf" {
  domain = desec_domain.domain.name
  subname = ""
  type = "TXT"
  records = [ "v=spf1 ip4:${local.mx_server} ~all" ]
  ttl = 86400
}
