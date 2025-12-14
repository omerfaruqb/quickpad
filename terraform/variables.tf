variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "enable_autopilot" {
  description = "Use GKE Autopilot (easier but less control)"
  type        = bool
  default     = false
}

variable "mongodb_password" {
  description = "MongoDB password (should be stored in secrets)"
  type        = string
  sensitive   = true
}

