import logging
import os
from google.cloud import storage
import google.cloud.logging

logging_client = google.cloud.logging.Client()
logging_client.get_default_handler()
logging_client.setup_logging()

storage_client = storage.Client()

CACHE_CONTROL_ENV = "CACHE_CONTROL_VALUE"


def handler(event, context):
    bucket = storage_client.get_bucket(event['bucket'])
    file = event['name']

    logging.info("Object '%s' was finalized", file)

    blob = bucket.get_blob(file)
    cache_control = os.environ.get(CACHE_CONTROL_ENV)

    if cache_control is not None:
        blob.cache_control = cache_control
        blob.patch()
        logging.info(
            "Successfully set cache-control metadata to '%s' on object '%s'", cache_control, file)
    else:
        logging.warning(
            "%s is not set, skipping caching headers", CACHE_CONTROL_ENV)

    blob.make_public()
    logging.info("Successfully set public ACL on object '%s'", file)
