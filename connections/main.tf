# FIXED: S3 to BigQuery Connection with Explicit Schema
resource "airbyte_connection" "my_connection" {
  source_id      = var.source_id
  destination_id = var.destination_id
  name          = var.name
  
  configurations = {
    sync_catalog = {
      streams = [{
        stream = {
          # Stream name that matches S3 file
          name = "customers_data"
          
          # CRITICAL: Define the complete schema explicitly  
          json_schema = jsonencode({
            type = "object"
            properties = {
              id = {
                type = "integer"
                description = "Customer unique identifier"
              }
              name = {
                type = "string"
                description = "Customer full name"
              }
              email = {
                type = "string"
                format = "email"
                description = "Customer email address"
              }
              age = {
                type = "integer"
                description = "Customer age in years"
              }
              department = {
                type = "string"
                description = "Customer department"
              }
              salary = {
                type = "integer"
                description = "Customer annual salary"
              }
              hire_date = {
                type = "string"
                format = "date"
                description = "Customer hire date (YYYY-MM-DD)"
              }
              city = {
                type = "string"
                description = "Customer city location"
              }
              status = {
                type = "string"
                enum = ["Active", "Inactive"]
                description = "Customer employment status"
              }
            }
            required = ["id", "name", "email", "age", "department", "salary", "hire_date", "city", "status"]
            additionalProperties = false
          })
          
          supported_sync_modes = ["full_refresh"]
          default_cursor_field = []
          source_defined_cursor = false
          source_defined_primary_key = []
        }
        
        config = {
          sync_mode = "full_refresh"
          destination_sync_mode = "overwrite"
          cursor_field = []
          primary_key = []
          alias_name = "customers_data"
          selected = true
          field_selection_enabled = false
          selected_fields = []
        }
      }]
    }
  }
  
  # Start with manual sync to test
  schedule = {
    schedule_type = "manual"
  }
  
  # Basic settings
  namespace_definition = var.namespace_definition
  namespace_format = var.namespace_format
  prefix = ""
  
}