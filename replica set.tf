provider "kubernetes" {
  config_context_cluster   = "minikube"
}
resource "kubernetes_horizontal_pod_autoscaler" "replica_set" {
  metadata {
    name = "replicaset"
     labels = {
      env = "dev"
      dc = "In"  
    }
  }
   spec {
    max_replicas = 5
    min_replicas = 3
  
     scale_target_ref {
       kind = "replication-controller"
       name = "Myreplicaset"
    }
   }
 }
resource "kubernetes_replication_controller" "rc" {
  metadata {
    name = "replication-controller"
  }

   spec {
    selector = {   
      env = "dev"
      dc = "In"  }
   replicas = 3
    template {
      metadata {
        labels = {
         env = "dev"
         dc = "In"
                }     
         }  
      spec {
       container {
          image = "nginx:1.7.8"
          name  = "rc-web"
                 } 
              } 
             } 
           }
         }