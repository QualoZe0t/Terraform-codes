variable "rdspasswd" {
  type = string
  default = "podpasswd"
  description = "Password for AWS-RDS MySQL Database"
}
variable "rdsusername" {
  type = string
  default = "admin"
  description = "Username for database"
}
variable "port" {
  type = string
  default = "30029"
  description = "Username for database"
}
