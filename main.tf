data "http" "airbyte_workspaces" {
  url    = "${var.SERVER_URL}/v1/workspaces"
  method = "POST"
  request_headers = {
    Authorization = "Basic YWlyYnl0ZTpwYXNzd29yZA=="
  }
}

module "s3_source" {
  source   = "./sources/s3"
  for_each = local.s3

  configuration = each.value.configuration
  source_name   = each.key
  workspace_id  = local.workspace_id
}

module "bigquery_destination" {
  source = "./destinations/bigquery"

  workspace_id  = local.big_query.workspace_id
  source_name   = local.big_query.name
  configuration = local.big_query.configuration
}

module "connections" {
  source   = "./connections"
  for_each = local.connections[trimprefix(terraform.workspace, "cne-airbyte-template-")]

  destination_id                       = each.value.destination_id
  name                                 = each.key
  namespace_definition                 = each.value.namespace_definition
  namespace_format                     = lookup(each.value, "namespace_format", null)
  non_breaking_schema_updates_behavior = each.value.non_breaking_schema_updates_behavior
  source_id                            = each.value.source_id
  status                               = each.value.status
  streams                              = each.value.streams
  schedule                             = each.value.schedule
}
