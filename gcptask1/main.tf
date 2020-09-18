module "gcpdev" {
     source = "./development"
     devvpcid = var.devvpcid
    
    // prodvpcid = module.gcpprod.vpcid
    // dbip = module.gcpprod.dbip
   //  dbuser = var.dbuser
    // dbname = var.dbname
   //  dbpass = var.dbpass
}
//module "gcpprod" {
   //  source = "./production"
  //   devvpcid = module.gcpdev.vpcid
   //  prodvpcid = var.prodvpcid
//     dbuser = var.dbuser
 //    dbname = var.dbname
   //  dbpass = var.dbpass
//}
