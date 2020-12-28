provider "google" {
  project = var.gcp_info.project
  region  = var.gcp_info.region
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.gcp_info.project}_artifacts_${var.service_name}"
  location = var.gcp_info.region

  # there's no need to keep these around, if we for some reason need to redeploy the same version it'll just be uploaded again
  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = 1
    }
  }
}

data "archive_file" "archive" {
  type        = "zip"
  output_path = "${path.module}/out/function.zip"
  source {
    content  = file("${path.module}/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "artifact" {
  name       = "${var.service_name}/function-${substr(filesha1(data.archive_file.archive.output_path), 0, 7)}.zip" # version the file to force redeployment of the function when it changes
  bucket     = google_storage_bucket.bucket.name
  source     = data.archive_file.archive.output_path
  depends_on = [data.archive_file.archive]
}

resource "google_cloudfunctions_function" "function" {
  name                  = var.service_name
  runtime               = "python38"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.artifact.name
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = var.gcp_info.upload_bucket
  }
  entry_point = var.function_info.entrypoint
  environment_variables = var.function_info.env
}
