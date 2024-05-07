resource "ovh_domain_zone_record" "thrift_vpn_dns" {
  zone      = var.dns_zone
  subdomain = var.region
  fieldtype = "A"
  ttl       = 60
  target    = data.aws_instance.thrift_vpn.public_ip
}
