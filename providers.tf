terraform {
  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.13.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.2"
    }
  }
  # backend "kubernetes" {
  #   secret_suffix = "cne-airbyte-template"
  #   namespace     = "airbyte"
  # }
}

provider "airbyte" {
  password = var.PASSWORD
  username = var.USERNAME
  server_url = var.SERVER_URL
}

provider "http" {}