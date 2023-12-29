locals {
  _cloud_vpn_gateways = [for i, v in var.cloud_vpn_gateways :
    merge(v, {
      create     = coalesce(lookup(v, "create", null), true)
      project_id = lower(trimspace(coalesce(lookup(v, "project_id", null), var.project_id)))
      network    = lower(trimspace(coalesce(lookup(v, "network", null), var.network)))
      region     = lower(trimspace(coalesce(lookup(v, "region", null), var.region)))
      stack_type = upper(trimspace(coalesce(lookup(v, "stack_type", null), "IPV4_ONLY")))
    })
  ]
  __cloud_vpn_gateways = [for i, v in local._cloud_vpn_gateways :
    merge(v, {
      name = lookup(v, "name", "vpngw-${v.network}")
    })
  ]
  cloud_vpn_gateways = [for i, v in local.__cloud_vpn_gateways :
    merge(v, {
      index_key = "${v.project_id}/${v.region}/${v.name}"
    }) if v.create == true
  ]
}

# Cloud HA VPN Gateway
resource "google_compute_ha_vpn_gateway" "default" {
  for_each   = { for k, v in local.cloud_vpn_gateways : v.index_key => v }
  project    = each.value.project_id
  name       = each.value.name
  network    = each.value.network
  region     = each.value.region
  stack_type = each.value.stack_type
}
