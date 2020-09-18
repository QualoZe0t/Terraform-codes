variable devvpcid {}

# variable prodvpcid {}
# variable dbip {}
# variable dbpass {}
# variable dbuser {}
# variable dbname {}

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
# resource "google_compute_network_peering" "peeringfromdev" {
#   name         = "peeringtoprod"
#   network      = "${google_compute_network.vpc_networkdev.id}"
#   peer_network = var.prodvpcid
# }
# resource "google_compute_instance" "devinstance" {
#   name         = "devinstance"
#   machine_type = "custom-2-2048"
#   zone         = "${google_compute_subnetwork.subnet-lab1.region}-b"

#   boot_disk {
#     initialize_params {
#       size = "20"
#       image = "rhel-8-v20200910"
#     }
#   }
#   scratch_disk {
#     interface = "SCSI"
#   }

#   network_interface {
#     network = "${google_compute_network.vpc_networkdev.name}"
#     subnetwork = "${google_compute_subnetwork.subnet-lab1.id}"
#   }
# }
resource "google_container_cluster" "gkecluster" {
  name     = "my-gke-cluster"
  location = "us-central1-c"
  project = var.devvpcid
  network = "${google_compute_network.vpc_networkdev.name}"
  subnetwork = "${google_compute_subnetwork.subnet-lab1.name}"
  initial_node_count = 1
  remove_default_node_pool = true
    master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  # node_config {
  #   oauth_scopes = [
  #     "https://www.googleapis.com/auth/logging.write",
  #     "https://www.googleapis.com/auth/monitoring",
  #   ]
  #   metadata = {
  #     disable-legacy-endpoints = "true"
  #   }
  #   labels = {
  #     app = "wordpress"
  #   }
  # }

}
resource "null_resource" "local1"  {
depends_on=[google_container_cluster.gkecluster] 
provisioner "local-exec" {
  command = "gcloud container clusters get-credentials ${google_container_cluster.gkecluster.name} --zone ${google_container_cluster.gkecluster.location}  --project ${google_container_cluster.gkecluster.project}"
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
    #preemptible  = true
    machine_type = "e2-medium"
    disk_size_gb = 10
    image_type = "cos_containerd"
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
       labels = {
      app = "wordpress"
    }
  }
}
# variable "op" {
#   default = 
# }

# resource "kubernetes_service" "service" {
#   depends_on=[
#     null_resource.local1,
#   ] 
#   metadata {
#     name = "wpsvcport"
#     }
#   spec {
#     type = "LoadBalancer"
#     selector = {
#       app = "wordpress"
#     }
  
#     session_affinity = "ClientIP"
#     port {
#       name        = "wp-port"
#       port        = 80    
#       target_port = "80"
    
#     }   
#   }
# }

# resource "kubernetes_replication_controller" "example" {
# depends_on=[
#     null_resource.local1,
#   ] 
# metadata {
#     name = "wprc"
#     labels = {
#       app = "wordpress"
#     }
#   }
#    spec {
#     selector = {   
#       app = "wordpress"
#         }
#    replicas = 1
#     template {
#       metadata {
#         labels = {
#          app= "wordpress"
#                 }     
#          }  
#   spec {
#     container {
#       image = "wordpress:latest"
#       name  = "wordpresscontainer"
#        port {
#             container_port = 80
#           }
      # env {
      #        name = "WORDPRESS_DB_HOST" 
      #        value =  var.dbip
      #     }
      # env {
      #    name = "WORDPRESS_DB_USER"
      #    value =  var.dbuser
      #     }
      # env {
      #        name = "WORDPRESS_DB_PASSWORD"
      #        value = var.dbpass
      #        }
      # env {
      #        name = "WORDPRESS_DB_NAME"
      #        value = var.dbname
      #        }
     # }
#     }
#     }
#   }
  
#   timeouts {
#     create = "60m"
#   }
# }
# output "wordpressip" {
#    value = kubernetes_service.service.load_balancer_ingress
# }

# data "google_compute_instance_group" "insgrp" {
#     self_link = "${google_container_node_pool.gkecluster_nodes.instance_group_urls}"
#     project = var.devvpcid
#     zone = "us-central1-c"
# }
# output "op4" {
#   value = data.google_compute_instance_group.insgrp.self_link
# }
# output "op5" {
#   value = data.google_compute_instance_group.insgrp.instances
# }

output "vpcid" {
  value = google_compute_network.vpc_networkdev.id
}

#Load balancer with unmanaged instance group 
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name = "lb-global-forwarding-rule"
  project = var.devvpcid
  target = google_compute_target_http_proxy.target_http_proxy.self_link
  port_range = "80"
}
# used by one or more global forwarding rule to route incoming HTTP requests to a URL map
resource "google_compute_target_http_proxy" "target_http_proxy" {
  name = "lb-proxy"
  project = var.devvpcid
  url_map = google_compute_url_map.url_map.self_link
}
# defines a group of virtual machines that will serve traffic for load balancing
resource "google_compute_backend_service" "backend_service" {
  name = "lb-backend-service"
  project = var.devvpcid
  port_name = "http"
  protocol = "HTTP"
  health_checks = ["${google_compute_health_check.healthcheck.self_link}"] 
  # backend {
  #   group = google_container_node_pool.gkecluster_nodes.instance_group_urls
  #   balancing_mode = "RATE"
  #   max_rate_per_instance = 100
  # }
}
determine whether instances are responsive and able to do work
resource "google_compute_health_check" "healthcheck" {
  name = "lb-healthcheck"
  timeout_sec = 1
  check_interval_sec = 1
  http_health_check {
    port = 80
  }
}# used to route requests to a backend service based on rules that you define for the host and path of an incoming URL
resource "google_compute_url_map" "url_map" {
  name = "lb-urlmap"
  project = var.devvpcid
  default_service = google_compute_backend_service.backend_service.self_link
}
# show external ip address of load balancer
output "load-balancer-ip-address" {
  value = google_compute_global_forwarding_rule.global_forwarding_rule.ip_address
}
