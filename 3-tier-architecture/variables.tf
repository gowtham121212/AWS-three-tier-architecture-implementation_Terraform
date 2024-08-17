variable "cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet1_cidr" {
  default = "10.0.0.0/24"
}

variable "public_subnet2_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet1_cidr" {
  default = "10.0.2.0/24"
}

variable "private_subnet2_cidr" {
  default = "10.0.3.0/24"
}

variable "db_subnet1_cidr" {
  default = "10.0.4.0/24"
}

variable "db_subnet2_cidr" {
  default = "10.0.5.0/24"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "db_instance_class" {
  default = "db.t2.micro"
}
