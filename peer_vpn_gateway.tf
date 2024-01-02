locals {
  redundancy_types = {
    1 = "SINGLE_IP_INTERNALLY_REDUNDANT"
    2 = "TWO_IPS_REDUNDANCY"
    3 = "TWO_IPS_REDUNDANCY"
    4 = "FOUR_IPS_REDUNDANCY"
  }
  _peer_vpn_gateways = [for i, v in var.peer_vpn_gateways :
    {
      create       = coalesce(lookup(v, "create", null), true)
      project_id   = coalesce(lookup(v, "project_id", null), var.project_id)
      name         = coalesce(lookup(v, "name", null), "peergw-${i}")
      description  = lookup(v, "description", null)
      ip_addresses = coalesce(lookup(v, "ip_addresses", null), [])
      labels       = coalesce(lookup(v, "labels", null), {})
    }
  ]
  peer_vpn_gateways = [for i, v in local._peer_vpn_gateways :
    merge(v, {
      redundancy_type = lookup(local.redundancy_types, length(v.ip_addresses), "TWO_IPS_REDUNDANCY")
      index_key       = "${v.project_id}/${v.name}"
    }) if v.create == true
  ]
}

resource "null_resource" "peer_vpn_gateways" {
  for_each = { for i, v in local.peer_vpn_gateways : v.index_key => true }
}

# Peer (External) VPN Gateway
resource "google_compute_external_vpn_gateway" "default" {
  for_each        = { for k, v in local.peer_vpn_gateways : v.index_key => v }
  project         = each.value.project_id
  name            = each.value.name
  description     = each.value.description
  labels          = each.value.labels
  redundancy_type = each.value.redundancy_type
  dynamic "interface" {
    for_each = each.value.ip_addresses
    content {
      id         = interface.key
      ip_address = interface.value
    }
  }
  depends_on = [null_resource.peer_vpn_gateways]
}
