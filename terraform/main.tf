# Cloud provider required, in this case using AWS
provider "aws" {
	region = "eu-west-1"
}

module myip {
	source = "4ops/myip/http"
	version = "1.0.0"
}

module "vpc" {
    source = "./modules/m_vpc"

    my_ip = module.myip.address
}

