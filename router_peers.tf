locals {
  _router_peers = [for i, v in concat(local.interconnect_attachments, local.vpn_tunnels) :
    {
      create                    = v.create
      project_id                = v.project_id
      name                      = lower(trimspace(coalesce(v.peer_bgp_name, "${v.name}-${i}")))
      region                    = v.region
      router                    = coalesce(lookup(v, "router", null), var.cloud_router)
      interface                 = v.interface_name
      peer_ip_address           = v.peer_ip_address
      peer_asn                  = coalesce(v.peer_asn, v.peer_is_gcp ? 64512 : 65000)
      advertised_groups         = coalesce(lookup(v, "advertised_groups", null), [])
      advertised_route_priority = coalesce(lookup(v, "advertised_priority", null), 100)
      advertised_ip_ranges      = coalesce(lookup(v, "advertised_ip_ranges", null), [])
      enable_bfd                = coalesce(lookup(v, "enable_bfd", null), false)
      bfd_min_transmit_interval = coalesce(lookup(v, "bfd_min_transmit_interval", null), 1000)
      bfd_min_receive_interval  = coalesce(lookup(v, "bfd_min_receive_interval", null), 1000)
      bfd_multiplier            = coalesce(lookup(v, "bfd_multiplier", null), 5)
      enable                    = coalesce(lookup(v, "enable", null), true)
      enable_ipv6               = coalesce(lookup(v, "enable_ipv6", null), false)
    }
  ]
  router_peers = [for i, v in local._router_peers :
    merge(v, {
      advertise_mode = length(v.advertised_ip_ranges) > 0 ? "CUSTOM" : "DEFAULT"
      index_key      = "${v.project_id}/${v.region}/${v.router}/${v.name}"
    }) if v.create == true
  ]
}

resource "google_compute_router_peer" "default" {
  for_each                  = { for i, v in local.router_peers : v.index_key => v }
  project                   = each.value.project_id
  name                      = each.value.name
  region                    = each.value.region
  router                    = each.value.router
  interface                 = each.value.interface
  peer_ip_address           = each.value.peer_ip_address
  peer_asn                  = each.value.peer_asn
  advertised_route_priority = each.value.advertised_route_priority
  advertised_groups         = each.value.advertised_groups
  advertise_mode            = each.value.advertise_mode
  dynamic "advertised_ip_ranges" {
    for_each = each.value.advertised_ip_ranges
    content {
      range       = advertised_ip_ranges.value.range
      description = advertised_ip_ranges.value.description
    }
  }
  dynamic "bfd" {
    for_each = [true] #each.value.enable_bfd ? [true] : []
    content {
      min_receive_interval        = each.value.bfd_min_receive_interval
      min_transmit_interval       = each.value.bfd_min_transmit_interval
      multiplier                  = each.value.bfd_multiplier
      session_initialization_mode = each.value.enable_bfd ? "ACTIVE" : "DISABLED"
    }
  }
  enable      = each.value.enable
  enable_ipv6 = each.value.enable_ipv6
  timeouts {
    create = null
    delete = null
    update = null
  }
  depends_on = [google_compute_router_interface.default]
}
