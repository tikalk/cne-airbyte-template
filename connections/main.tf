resource "airbyte_connection" "my_connection" {
  destination_id                       = var.destination_id
  name                                 = var.name
  namespace_definition                 = var.namespace_definition
  namespace_format                     = var.namespace_format
  non_breaking_schema_updates_behavior = var.non_breaking_schema_updates_behavior
  source_id                            = var.source_id
  status                               = var.status
  configurations = {
    streams = var.streams
  }
  schedule = var.schedule
}