
resource "airbyte_source_s3" "s3_source" {
  configuration = var.configuration
  workspace_id = var.workspace_id
  name         = "${var.source_name} (${upper(trimprefix(terraform.workspace,"cne-airbyte-template-"))})"
}