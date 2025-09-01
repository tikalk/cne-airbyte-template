variable "workspace_id" {
  type = string
}

variable "source_name" {
  type = string
}

variable "configuration" {
  type = object({
    big_query_client_buffer_size_mb = number
    credentials_json                = string
    dataset_id                      = string
    dataset_location                = string
    disable_type_dedupe             = bool
    loading_method                  = object({
      standard_inserts = object({})
    })
    project_id                      = string
  })
}
