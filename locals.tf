locals {
  # workspace_id = jsondecode(data.http.airbyte_workspaces.response_body).workspaces[0].workspaceId
  workspace_id      = var.WORKSPACE_ID
  namespace_formats = jsondecode(file(var.source_table_names_file))
  connections = {
    staging = local.connections_stage
    dev     = local.connections_dev
    prod    = local.connections_prod
  }
  s3 = {
    "customers_data" = {
      configuration = {
        aws_access_key_id     = var.AWS_ACCESS_KEY_ID
        aws_secret_access_key = var.AWS_SECRET_ACCESS_KEY
        bucket                = "cne-ai-airbyte-source"
        streams = [
          {
            name                            = "customers_data"
            days_to_sync_if_history_is_full = 3
            schemaless                      = true
            globs                           = ["customers_data.csv"]
            validation_policy               = "Emit Record"
            format = {
              "csv_format" = {
                header_definition = {
                  from_csv = {}
                }
                delimiter               = ","
                double_quote            = true
                encoding                = "utf8"
                quote_char              = "\""
                skip_rows_after_header  = 0
                skip_rows_before_header = 0
                false_values            = ["0", "False", "FALSE", "false"]
                null_values = [
                  " ", "#N/A", "#N/A N/A", "#NA", "-1.#IND", "-1#.QNAN", "-NaN", "1.#IND", "1#.QNAN", "N/A", "NA",
                  "NULL", "NaN", "n/a", "nan", "null", "-nan"
                ]
                true_values         = ["1", "True", "TRUE", "true"]
                strings_can_be_null = false
              }
            }
          },
        ]
      }
      workspace_id = local.workspace_id
    },
  }
  big_query = {
    configuration = {
      big_query_client_buffer_size_mb = 15
      credentials_json                = var.SERVICE_ACCOUNT_INFO
      dataset_id                      = "cne_ai_dataplatform_demo"
      dataset_location                = "europe-central2"
      disable_type_dedupe             = false
      loading_method = {
        standard_inserts = {}
      }
      project_id = var.BIGQUERY_PROJECT_ID
    }
    name         = "BigQuery (${upper(trimprefix(terraform.workspace, "cne-airbyte-template-"))})"
    workspace_id = local.workspace_id,
  }
}
