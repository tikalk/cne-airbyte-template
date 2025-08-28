terraform {
  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.13.0"
    }
  }
}

provider "airbyte" {
  username   = var.AIRBYTE_USERNAME
  password   = var.AIRBYTE_PASSWORD
  server_url = var.AIRBYTE_SERVER_URL
}


