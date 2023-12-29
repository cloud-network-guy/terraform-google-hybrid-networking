locals {
  _interconnect_attachments = flatten([
    for i, v in var.interconnects : [
      for a, attachment in v.attachments : {
        create               = lookup(v, "create", true)
        is_interconnect      = true
        is_vpn               = false
        peer_is_gcp          = false
        type                 = upper(coalesce(lookup(v, "type", null), "PARTNER"))
        project_id           = coalesce(lookup(v, "project_id", null), var.project_id)
        name                 = coalesce(lookup(attachment, "name", null), "attachment-${i}-${a}")
        description          = lookup(attachment, "description", null)
        region               = coalesce(lookup(v, "region", null), var.region)
        router               = coalesce(lookup(v, "cloud_router", null), var.cloud_router)
        interface_name       = attachment.interface_name
        peer_bgp_ip          = attachment.peer_bgp_name
        peer_bgp_name        = attachment.peer_bgp_name
        peer_asn             = coalesce(lookup(attachment, "peer_bgp_asn", null), 16550)
        advertised_ip_ranges = lookup(v, "advertised_ip_ranges", null)
        advertised_groups    = []
        advertised_priority  = lookup(attachment, "advertised_priority", lookup(v, "advertised_priority", null))
        ip_range             = attachment.cloud_router_ip
        peer_ip_address      = attachment.peer_bgp_ip
        mtu                  = coalesce(lookup(attachment, "mtu", lookup(v, "mtu", null)), 1440)
        admin_enabled        = true #coalesce(attachment.enable, true)
        encryption           = "NONE"
      }
    ]
  ])
  interconnect_attachments = [
    for i, v in local._interconnect_attachments :
    merge(v, {
      interconnect    = v.type == "DEDICATED" ? v.interconnect : null
      attachment_name = v.name
      index_key       = "${v.project_id}/${v.region}/${v.name}"
    }) if v.create == true
  ]
}

# Interconnect Attachment
resource "google_compute_interconnect_attachment" "default" {
  for_each                 = { for i, v in local.interconnect_attachments : v.index_key => v }
  project                  = each.value.project_id
  name                     = each.value.name
  description              = each.value.description
  region                   = each.value.region
  router                   = each.value.router
  ipsec_internal_addresses = []
  encryption               = each.value.encryption
  mtu                      = each.value.mtu
  admin_enabled            = each.value.admin_enabled
  type                     = each.value.type
  interconnect             = each.value.interconnect
  timeouts {
    create = null
    delete = null
    update = null
  }
  #  depends_on               = [google_compute_router.default]
}
