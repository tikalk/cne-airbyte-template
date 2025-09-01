variable "WORKSPACE_ID" {
  description = "The id of prod workspace for Airbyte"
  type        = string
}

variable "PASSWORD" {
  description = "The password for Airbyte"
  type        = string
}

variable "USERNAME" {
  description = "The username for Airbyte"
  type        = string
}

variable "SERVER_URL" {
  description = "The URL for Airbyte server"
  type        = string
}

variable "SERVICE_ACCOUNT_INFO" {
  description = "The certificate for GCP - Json format"
  type        = string
}

variable "GOOGLE_MEETING_SA" {
  description = "The certificate for Google API and Cloud Storage - Json format"
  type        = string
}

variable "AWS_ACCESS_KEY_ID" {
  description = "The access key for AWS account"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "The secret key for AWS account"
  type        = string
}

variable "BIGQUERY_PROJECT_ID" {
  description = "The project id for big query"
  type        = string
}

variable "source_table_names_file" {
  description = "Path to the namespace_formats JSON file"
  default     = "./source_table_names.json" # Adjust the path as needed
}

variable "source_table_names" {
  type        = map(string)
  description = "Namespace formats loaded from JSON"
  default     = {}
}

variable "OPENAI_API_KEY" {
  description = "The OpenAI API key for Milvus embeddings"
  type        = string
}
