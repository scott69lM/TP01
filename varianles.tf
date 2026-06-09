variable "bucket_prefix" {
  type        = string
  description = "Prefixe du bucket"
  default     = "formation-tp01"
}

variable "environment" {
  type        = string
  description = "Environnement"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "owner" {
  type        = string
  description = "Email de l'owner du bucket"
}