locals {
  BIGQUERY_NAME_DEV = "BigQuery (DEV)"
  connections_dev = {
    "customers_data → ${local.BIGQUERY_NAME_DEV}" = {
      source_id            = module.s3_source["customers_data"].source_id
      destination_id       = module.bigquery_destination.destination_id
      namespace_definition = "custom_format"
      namespace_format     = local.namespace_formats["cne-ai_customers_data"]
    },
  }
}
