variable "destination_id" {
  type = string
  description = "Airbyte destination ID"
}

variable "name" {
  type = string
  description = "Connection name"
}

variable "namespace_definition" {
  type = string
  description = "Namespace definition type"
}

variable "namespace_format" {
  type = string
  description = "Namespace format string"
}

variable "source_id" {
  type = string
  description = "Airbyte source ID"
}
