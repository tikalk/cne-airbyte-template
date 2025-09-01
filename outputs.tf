output "bigquery_destination_id" {
  value = module.bigquery_destination.destination_id
}

output "s3_source_ids" {
  value = { for key, source in module.s3_source : key => source.source_id }
}

# This will output the first workspace ID found in the list. Adjust accordingly based on your needs.
output "workspace_id" {
  # value = jsondecode(data.http.airbyte_workspaces.response_body).workspaces[0].workspaceId
  value = var.WORKSPACE_ID
}
