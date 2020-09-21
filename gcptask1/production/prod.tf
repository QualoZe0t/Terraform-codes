variable devvpcid {}
variable prodvpcid {}
variable dbuser {}
variable dbpass {}
variable dbname {}
provider "google"  {
  project     = var.prodvpcid
  region      = "asia-southeast1"
}

resource "google_compute_network" "vpc_networkprod" {
  name = "vpc-network-production"
  description = "This VPC is for production project"
  project     = var.prodvpcid
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
}
resource "google_compute_subnetwork" "subnet-lab2" {
  name          = "lab2"
  ip_cidr_range = "10.0.2.0/24"
  region        = "asia-southeast1"
  network       = google_compute_network.vpc_networkprod.id
  project     = var.prodvpcid
}
resource "google_compute_firewall" "prod" {
  name    = "prod-firewall"
  project     = var.prodvpcid
  description = "This firewall is for production project"
  network = google_compute_network.vpc_networkprod.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_network_peering" "peeringfromprod" {
  depends_on=[
    var.devvpcid, var.prodvpcid
  ]
  name         = "peeringtodev"
  network      = "${google_compute_network.vpc_networkprod.id}"
  peer_network = var.devvpcid
}
resource "google_compute_instance" "prodinstance" {
  name         = "prodinstance"
  machine_type = "custom-2-2048"
  zone         = "${google_compute_subnetwork.subnet-lab2.region}-b"
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
    network = "${google_compute_network.vpc_networkprod.name}"
    subnetwork = "${google_compute_subnetwork.subnet-lab2.id}"
  }
}

resource "google_sql_database_instance" "mysqldbinstance" {
  name             = "mysqldbinstance1"
  root_password    = "akhil29"
  database_version = "MYSQL_5_7"
  region           = "${google_compute_subnetwork.subnet-lab2.region}"
  project          = var.prodvpcid      
  settings {
    disk_size = "10"
    disk_type = "PD_SSD"
    tier = "db-f1-micro"
    availability_type = "REGIONAL"
    backup_configuration {
      enabled = true
      binary_log_enabled = true
       }
    ip_configuration {
     ipv4_enabled = true    
     authorized_networks{
         name="public-network"
         value="0.0.0.0/0"
       }
   }
  }
}

resource "google_sql_database" "database" {
  name     = var.dbname
  instance = google_sql_database_instance.mysqldbinstance.name
  project  = var.prodvpcid
}
resource "google_sql_user" "users" {
  name     = var.dbuser 
  password = var.dbpass
  instance = google_sql_database_instance.mysqldbinstance.name
  project  = var.prodvpcid     
}

output "vpcid" {
  value = google_compute_network.vpc_networkprod.id
}
output "dbip" {
  value = google_sql_database_instance.mysqldbinstance.public_ip_address
}
