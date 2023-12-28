locals {
  _interconnect_attachments = flatten([
    for i, v in var.interconnects : [
      for c, circuit in v.circuits : {
        create            = coalesce(v.create, true)
        is_interconnect   = true
        is_vpn            = false
        project_id        = coalesce(v.project_id, var.project_id)
        name              = coalesce(circuit.name, "interconnect-${i}-${c}")
        description       = circuit.description
        region            = coalesce(v.region, var.region)
        interconnect_type = upper(coalesce(v.type, "PARTNER"))
        ip_range          = circuit.cloud_router_ip
        mtu               = coalesce(circuit.mtu, v.mtu, 1440)
        admin_enabled     = true #coalesce(circuit.enable, true)
      }
    ]
  ])
  interconnect_attachments = [
    for i, v in local._interconnect_attachments :
    merge(v, {
      interconnect = v.type == "DEDICATED" ? v.interconnect : null
      index_key    = "${v.project_id}/${v.region}/${v.name}"
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
  #  depends_on               = [google_compute_router.default]
}
