terraform {
    required_providers {
        google = {
            source  = "hashicorp/google"
                version = ">= 3.35.0"
        }
    }

    required_version = ">= 0.13.0"
}


provider "google" {
  credentials = file(var.credentials)
  region      = var.region
  zone        = var.zone
  project     = var.project
}
