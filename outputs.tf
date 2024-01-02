
output "cloud_vpn_gateways" {
  value = { for i, v in local.cloud_vpn_gateways :
    v.index_key => {
      index_key    = v.index_key
      name         = v.name
      region       = v.region
      ip_addresses = try(google_compute_ha_vpn_gateway.default[v.index_key].vpn_interfaces.*.ip_address, [])
    }
  }
}

output "peer_vpn_gateways" {
  value = { for i, v in local.peer_vpn_gateways :
    v.index_key => {
      index_key       = v.index_key
      name            = v.name
      redundancy_type = v.redundancy_type
      ip_addresses = [
        for interface in try(google_compute_external_vpn_gateway.default[v.index_key].interface, []) : interface.ip_address
      ]
    }
  }
}

output "vpn_tunnels" {
  value = { for i, v in local.vpn_tunnels :
    v.index_key => {
      index_key               = v.index_key
      name                    = v.name
      cloud_router_ip_address = v.ip_range
      peer_ip_address         = v.peer_ip_address
      peer_gateway_ip         = try(google_compute_vpn_tunnel.default[v.index_key].peer_ip, null)
      cloud_vpn_gateway_ip    = try(data.google_compute_ha_vpn_gateway.default[v.cloud_vpn_gateway_key].vpn_interfaces.*.ip_address[v.tunnel_index], "unknown")
      ike_version             = v.ike_version
      shared_secret           = v.shared_secret
      detailed_status         = try(google_compute_vpn_tunnel.default[v.index_key].detailed_status, "Unknown")
    }
  }
}

output "interconnect_attachments" {
  value = {
    for i, v in local.interconnect_attachments :
    v.index_key => {
      index_key                  = v.index_key
      name                       = v.name
      bandwidth                  = try(google_compute_interconnect_attachment.default[v.index_key].bandwidth, "Unknown")
      edge_availability_domain   = v.type == "PARTNER" ? google_compute_interconnect_attachment.default[v.index_key].edge_availability_domain : null
      vlan_tag8021q              = try(google_compute_interconnect_attachment.default[v.index_key].vlan_tag8021q, 0)
      pairing_key                = v.type == "PARTNER" ? google_compute_interconnect_attachment.default[v.index_key].pairing_key : null
      private_interconnect_info  = v.type == "DEDICATED" ? google_compute_interconnect_attachment.default[v.index_key].private_interconnect_info : null
      cloud_router_ip_address    = try(google_compute_interconnect_attachment.default[v.index_key].cloud_router_ip_address, "Unknown")
      customer_router_ip_address = try(google_compute_interconnect_attachment.default[v.index_key].customer_router_ip_address, "Unknown")
      state                      = try(google_compute_interconnect_attachment.default[v.index_key].state, "Unknown")
    }
  }
}
