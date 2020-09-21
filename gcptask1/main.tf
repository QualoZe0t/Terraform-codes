module "gcpdev" {
     source = "./development"
     devvpcid = var.devvpcid
     username = var.username
     password = var.password
     prodvpcid = module.gcpprod.vpcid
}

module "gcpprod" {
     source = "./production"
     devvpcid = module.gcpdev.vpcid
     prodvpcid = var.prodvpcid
     dbuser = var.dbuser
     dbname = var.dbname
     dbpass = var.dbpass
}

module "k8s" {
   source = "./devk8s"
   dbuser                 = var.dbuser    
   dbname                 = var.dbname
   dbpass                 = var.dbpass
   username               = var.username
   password               = var.password
   dbip                   = module.gcpprod.dbip
   nodepool               = module.gcpdev.nodepool
   host                   = module.gcpdev.host
   client_certificate     = module.gcpdev.client_certificate
   client_key             = module.gcpdev.client_key
   cluster_ca_certificate = module.gcpdev.cluster_ca_certificate
}
