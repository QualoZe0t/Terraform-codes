variable devvpcid {}
variable username {}
variable password {}
variable prodvpcid {}

provider "google" {
  project     = var.devvpcid
  region      = "us-central1"
}

resource "google_compute_network" "vpc_networkdev" {
  name = "vpc-network-development"
  description = "This VPC is for development project"
  project     = var.devvpcid
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet-lab1" {
  name          = "lab1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_networkdev.id
  project     = var.devvpcid
}
resource "google_compute_firewall" "prod" {
  name    = "dev-firewall"
  project     = var.devvpcid
  description = "This firewall is for development project"
  network = google_compute_network.vpc_networkdev.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
 }
resource "google_compute_network_peering" "peeringfromdev" {
  depends_on=[
    var.devvpcid, var.prodvpcid
  ]
  name         = "peeringtoprod"
  network      = "${google_compute_network.vpc_networkdev.id}"
  peer_network = var.prodvpcid
}
resource "google_compute_instance" "devinstance" {
  name         = "devinstance"
  machine_type = "custom-2-2048"
  zone         = "${google_compute_subnetwork.subnet-lab1.region}-b"

  boot_disk {
    initialize_params {
      size = "20"
      image = "rhel-8-v20200910"
    }
  }
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = "${google_compute_network.vpc_networkdev.name}"
    subnetwork = "${google_compute_subnetwork.subnet-lab1.id}"
  }
}
resource "google_container_cluster" "gkecluster" {
  name     = "my-gke-cluster"
  location = "us-central1-c"
  project = var.devvpcid
  network = google_compute_network.vpc_networkdev.name
  subnetwork = google_compute_subnetwork.subnet-lab1.name
  initial_node_count = 1
  remove_default_node_pool = true
  master_auth {
    username = var.username
    password = var.password
  }
}
resource "null_resource" "local1"  {
depends_on=[google_container_cluster.gkecluster] 
provisioner "local-exec" {
  command = "gcloud container clusters get-credentials 
  ${google_container_cluster.gkecluster.name} --zone ${google_container_cluster.gkecluster.location} --project ${google_container_cluster.gkecluster.project}"
   }
}

resource "google_container_node_pool" "gkecluster_nodes" {
  name       = "my-node-pool"
  location   = "us-central1-c"
  cluster    = google_container_cluster.gkecluster.name
  node_count = 3
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 10
    image_type = "cos_containerd"
    metadata = {
     disable-legacy-endpoints = "true"
     }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/compute",
    ]
       labels = {
      app = "wordpress"
    }
  }
}

output "vpcid" {
  value = google_compute_network.vpc_networkdev.id
}

output "nodepool" {
  value = google_container_node_pool.gkecluster_nodes.id
}
output "client_certificate" {
  value     = "${google_container_cluster.gkecluster.master_auth.0.client_certificate}"
  sensitive = true
}

output "client_key" {
  value     = "${google_container_cluster.gkecluster.master_auth.0.client_key}"
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = "${google_container_cluster.gkecluster.master_auth.0.cluster_ca_certificate}"
  sensitive = true
}

output "host" {
  value     = "${google_container_cluster.gkecluster.endpoint}"
  sensitive = true
}  
