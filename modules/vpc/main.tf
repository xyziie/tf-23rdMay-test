################################################################################
# modules/vpc/main.tf
#
# Creates a custom-mode VPC with:
#   - One or more subnets with secondary IP ranges (required for GKE/Composer)
#   - Cloud Router + Cloud NAT (so Composer workers reach internet without
#     public IPs)
#   - Private Google Access enabled on every subnet (reach Google APIs
#     without traversing the internet)
################################################################################

# ── VPC Network ───────────────────────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.env}-vpc"
  auto_create_subnetworks = false          # custom mode — we control all subnets
  routing_mode            = var.routing_mode
  description             = "Custom VPC for ${var.env} environment — managed by Terraform"
}

# ── Subnets ───────────────────────────────────────────────────────────────────
resource "google_compute_subnetwork" "subnets" {
  for_each = { for s in var.subnets : s.name => s }

  project                  = var.project_id
  name                     = each.value.name
  region                   = each.value.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = each.value.cidr
  private_ip_google_access = true   # reach Google APIs without public IPs

  # Secondary ranges are required for GKE (and therefore Composer) —
  # one range for Pods, one for Services.
  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ranges", [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.cidr
    }
  }

  # VPC Flow Logs — useful for debugging Composer networking issues
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# ── Cloud Router ──────────────────────────────────────────────────────────────
# Required by Cloud NAT. One router per region.
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.env}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# ── Cloud NAT ─────────────────────────────────────────────────────────────────
# Gives private Composer worker nodes outbound internet access (e.g. pip install,
# pulling images from Docker Hub) without assigning public IPs to the nodes.
resource "google_compute_router_nat" "nat" {
  project = var.project_id
  name    = "${var.env}-nat"
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ── Firewall: Allow IAP SSH ───────────────────────────────────────────────────
# Allows SSH via Identity-Aware Proxy to any VM tagged `allow-iap`.
# Useful for debugging Composer GKE nodes.
resource "google_compute_firewall" "allow_iap_ssh" {
  project     = var.project_id
  name        = "${var.env}-allow-iap-ssh"
  network     = google_compute_network.vpc.name
  description = "Allow SSH from Identity-Aware Proxy"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["35.235.240.0/20"]   # IAP IP range — Google-managed
  target_tags   = ["allow-iap"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# ── Firewall: Allow Internal ──────────────────────────────────────────────────
# Allows all traffic between nodes within the VPC (required for GKE pod comms).
resource "google_compute_firewall" "allow_internal" {
  project     = var.project_id
  name        = "${var.env}-allow-internal"
  network     = google_compute_network.vpc.name
  description = "Allow all internal traffic within the VPC"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = [for s in var.subnets : s.cidr]
  target_tags   = ["internal"]

  allow {
    protocol = "all"
  }
}

# ── Firewall: Allow LB Health Checks ─────────────────────────────────────────
resource "google_compute_firewall" "allow_lb_health_checks" {
  project     = var.project_id
  name        = "${var.env}-allow-lb-health-checks"
  network     = google_compute_network.vpc.name
  description = "Allow GCP load balancer health check probes"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["allow-health-check"]

  allow {
    protocol = "tcp"
  }
}
