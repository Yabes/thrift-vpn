provider "aws" {
  region = var.region
}

provider "null" {}

provider "ovh" {
  endpoint = "ovh-eu"
}
