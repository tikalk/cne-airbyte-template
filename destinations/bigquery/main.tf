resource "airbyte_destination_bigquery" "bigquery_destination" {
  configuration = var.configuration
  name          = var.source_name
  workspace_id  = var.workspace_id
}