variable "service_name" {
    type = string
    default = "sharex-upload-post-processing"
}

variable "gcp_info" {
    type = object({
        project = string
        region = string
        upload_bucket = string
    })
    default = {
        project = "sweepyoface"
        region = "us-central1" # cloud storage must be available here
        upload_bucket = "u.sweepy.dev"
    }
}

variable "function_info" {
    type = object({
        entrypoint = string
        env = map(string)
    })
    default = {
        entrypoint = "handler"
        env = {"CACHE_CONTROL_VALUE": "public, max-age=31536000"}
    }
}