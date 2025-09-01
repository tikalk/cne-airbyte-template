variable "source_name" {
  type = string
}

variable "workspace_id" {
  type = string
}

variable "configuration" {
  type = object({
    aws_access_key_id     = string
    aws_secret_access_key = string
    bucket                = string

    streams = list(object({
      name                            = string
      globs                           = list(string)
      input_schema                    = optional(string)
      schemaless                      = bool
      validation_policy               = string
      days_to_sync_if_history_is_full = optional(number)

      format = object({
        # Only one of these should be set per stream

        csv_format = optional(object({
          delimiter = string
          header_definition = object({
            from_csv = object({})
          })
          double_quote            = bool
          encoding                = string
          false_values            = list(string)
          null_values             = list(string)
          true_values             = list(string)
          quote_char              = string
          skip_rows_after_header  = number
          skip_rows_before_header = number
          strings_can_be_null     = bool
        }))

        unstructured_document_format = optional(object({
          strategy = string
          processing = object({
            mode = string
          })
          skip_unprocessable_files = bool
        }))
      })
    }))
  })
}
