locals {
  _interconnect_attachments = flatten([
    for i, v in var.interconnects : [
      for a, attachment in v.attachments : {
        create          = coalesce(v.create, true)
        is_interconnect = true
        is_vpn          = false
        peer_is_gcp     = false
        #attachment_name      = attachment.name,
        type                 = upper(coalesce(v.type, "PARTNER"))
        project_id           = coalesce(v.project_id, var.project_id)
        name                 = coalesce(attachment.name, "attachment-${i}-${a}")
        description          = attachment.description
        region               = coalesce(v.region, var.region)
        router               = v.cloud_router
        interface_name       = attachment.interface_name
        peer_bgp_ip          = attachment.peer_bgp_name
        peer_bgp_name        = attachment.peer_bgp_name
        peer_asn             = coalesce(attachment.peer_bgp_asn, 16550)
        advertised_ip_ranges = coalesce(v.advertised_ip_ranges, [])
        advertised_groups    = []
        advertised_priority  = coalesce(attachment.advertised_priority, v.advertised_priority, 100)
        ip_range             = attachment.cloud_router_ip
        peer_ip_address      = attachment.peer_bgp_ip
        mtu                  = coalesce(attachment.mtu, v.mtu, 1440)
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
