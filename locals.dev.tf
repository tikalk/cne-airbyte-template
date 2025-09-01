locals {
  BIGQUERY_NAME_DEV = "BigQuery (DEV)"
  connections_dev = {
    "customers_data → ${local.BIGQUERY_NAME_DEV}" = {
      source_id                            = module.s3_source["customers_data"].source_id
      destination_id                       = module.bigquery_destination.destination_id
      status                               = "active"
      non_breaking_schema_updates_behavior = "ignore"
      namespace_definition                 = "custom_format"
      namespace_format                     = local.namespace_formats["cne-ai_customers_data"]
      schedule = {
        schedule_type   = "manual"
        cron_expression = ""
      }
      streams = [
        {
          sync_mode = "full_refresh_overwrite"
          name      = "customers_data"
          selected  = true
        }
      ]
    },
  }
}
