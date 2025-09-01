variable "destination_id" {
  type = string
}

variable "name" {
  type = string
}

variable "namespace_definition" {
  type = string
}

variable "namespace_format" {
  type = string
}

variable "non_breaking_schema_updates_behavior" {
  type = string
}

variable "source_id" {
  type = string
}

variable "status" {
  type = string
}

variable "schedule" {
  type = object({
    schedule_type   = string
    cron_expression = string
  })
}

variable "streams" {
  type = list(object({
    sync_mode   = string
    name        = string
    selected    = bool
    primary_key = optional(list(list(string)))

  }))
}
