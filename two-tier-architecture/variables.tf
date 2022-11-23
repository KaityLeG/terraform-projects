
variable "vpc_cidr" {
  description = "custom vpc CIDR notation"
  type        = string
  default     = "10.0.0.0/16"
}


variable "ec2_type" {
  description = "ec2 instance id"
  type = string
  default = "t2.micro"
}

variable "ec2_ami" {
  description = "ec2 linux ami"
  type = string
  default = "ami-0c02fb55956c7d316"
}

variable "az1" {
  description = "az1"
  type = string
  default = "us-east-1a"
}


variable "az2" {
  description = "az2"
  type = string
  default = "us-east-1b"
}

variable "public_subnet1" {
    description = "public subnet 1 CIDR notation"
    type = string
    default = "10.0.2.0/24"
  
}

variable "public_subnet2" {
    description = "public subnet 2 CIDR notation"
    type = string
    default = "10.0.3.0/24"
  
}

variable "private_subnet1" {
  description = "private subnet 1 CIDR notation"
  type        = string
  default     = "10.0.4.0/24"
}

variable "private_subnet2" {
  description = "private subnet 2 CIDR notation"
  type        = string
  default     = "10.0.5.0/24"
}

variable "db_engine" {
  description = "db engine"
  type        = string
  default     = "mysql"
}


# db engine version
variable "db_engine_version" {
  description = "db engine version"
  type        = string
  default     = "5.7"
}


# db name
variable "db_name" {
  description = "db name"
  type        = string
  default     = "my_db"
}

variable "db_name2" {
  description = "db name"
  type        = string
  default     = "my_db2"
}


# db instance class
variable "db_instance_class" {
  description = "db instance class"
  type        = string
  default     = "db.t2.micro"
}
             

# database username variable
variable "db_username" {
  description = "database admin username"
  type        = string
  sensitive   = true
}


# database password variable
variable "db_password" {
  description = "database admin password"
  type        = string
  sensitive   = true
}
