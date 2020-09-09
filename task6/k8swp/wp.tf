variable "rdsendpoint" {}
variable "rdspasswd" {}
variable "port" {}
variable "rdsdbname" {}
variable "rdsusername" {}
provider "kubernetes" {
  config_context_cluster   = "minikube"
}
resource "null_resource" "minikube" {
  provisioner "local-exec" {
    command = "minikube start"
  }
}
resource "kubernetes_service" "wpservice" {
  metadata {
    name = "wpserviceport"
    labels = {
      app = "wordpress"
    }
    }
  spec {
    type = "NodePort"
    selector = {
      app = "${kubernetes_replication_controller.wordpressrc
      .metadata.0.labels.app}"
    }
  
    session_affinity = "ClientIP"
    port {
      name        = "wp-port"
      port        = 80    
      target_port = "80"
      node_port = var.port
    }   
  }
}

resource "kubernetes_replication_controller" "wordpressrc" {
  metadata {
    name = "replication-controller-wordpress"
    labels = {
      app = "wordpress"
    }
  }
 
   spec {
    selector = {   
      app = "wordpress"
        }
   replicas = 1
    template {
      metadata {
        labels = {
         app= "wordpress"
                }     
         }  
      spec {
       container {
          image = "wordpress:latest"
          name  = "wordpresscontainer"
          port {
            container_port = 80
          }
          env {
             name = "WORDPRESS_DB_HOST" 
             value =  var.rdsendpoint
             }
           env {
             name = "WORDPRESS_DB_USER"
             value =  var.rdsusername
             }
              env {
             name = "WORDPRESS_DB_PASSWORD"
             value = var.rdspasswd
             }
              env {
             name = "WORDPRESS_DB_NAME"
             value = var.rdsdbname
             }
         
                } 
          
                }
              }
            }
           }
