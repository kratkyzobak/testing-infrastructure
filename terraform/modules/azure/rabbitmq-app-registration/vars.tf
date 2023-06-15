variable "unique_project_name" {
  type        = string
  description = "Value to make unique every resource name generated"
}

variable "rabbitmq_access_identities" {
  type        = list(any)
  description = "Identities with access to RabbitMQ API"
  default     = [{"principal_id": "20b1b5f8-67b6-460c-8074-b7f836fc06df"}]
}