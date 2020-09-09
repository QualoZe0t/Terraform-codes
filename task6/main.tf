module "awsrds" {
     source = "./awsrds"
     rdspasswd = var.rdspasswd
     rdsusername = var.rdsusername
}

module "k8swp" {
     source = "./k8swp"
   
     rdsendpoint = module.awsrds.rds_dbhost
     rdsusername = var.rdsusername
     rdsdbname = module.awsrds.rds_dbname
     rdspasswd = var.rdspasswd
     port = var.port
}

resource "null_resource" "wppod" {
  depends_on = [
    module.k8swp
  ]
  provisioner "local-exec" {
    command = "firefox 192.168.99.100:${var.port}"
  }
}
