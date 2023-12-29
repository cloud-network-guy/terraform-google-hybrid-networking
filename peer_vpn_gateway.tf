locals {
  redundancy_types = {
    1 = "SINGLE_IP_INTERNALLY_REDUNDANT"
    2 = "TWO_IPS_REDUNDANCY"
    3 = "TWO_IPS_REDUNDANCY"
    4 = "FOUR_IPS_REDUNDANCY"
  }
  _peer_vpn_gateways = [for i, v in var.peer_vpn_gateways :
    {
      create       = lookup(v, "create", true)
      project_id   = lookup(v, "project_id", var.project_id)
      name         = lookup(v, "name", "peergw-${i}")
      description  = v.description
      ip_addresses = lookup(v, "ip_addresses", [])
      labels       = lookup(v, "labels", {})
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
