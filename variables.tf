variable "access_key" {
     default = "AKIASZLBBA6SVJ6UQTGM"
}
variable "secret_key" {
     default = "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"
}
variable "region" {
     default = "us-east-1"
}
variable "availabilityZoneone" {
     default = ["us-east-1a","us-east-1c"]
     type = list
}

variable "availabilityZonetwo" {
     default = "us-east-1b"
}

variable "instanceTenancy" {
    default = "default"
}
variable "dnsSupport" {
    default = true
}
variable "dnsHostNames" {
    default = true
}
variable "vpcCIDRblock" {
    default = "10.0.0.0/16"
}
variable "subnetCIDRblockone" {
    default = [ "10.0.1.0/24","10.0.3.0/24"]
    type = list
    
}

    
variable "subnetCIDRblocktwo" {
    default = "10.0.2.0/24"
}

variable "destinationCIDRblock" {
    default = "0.0.0.0/0"
}
variable "ingressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
variable "egressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
variable "mapPublicIP" {
    default = true
}
variable "amiid" {
	default = "ami-00ddb0e5626798373"
	
}
variable "instype" {
	default = "t2.micro"
	
}
