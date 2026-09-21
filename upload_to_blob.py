
import os
import logging
from azure.storage.blob import BlobServiceClient
from modules_email.email_handler import send_failure_email, send_expiry_email


# Ensure logging is configured at the application entry point.
logging.getLogger('azure').setLevel(logging.WARNING)

def upload_to_blob(settings):
    operation = "Upload to Blob"
    logging.info("Starting the upload process to Azure Blob Storage.")

    # Initialize lists to store uploaded and failed uploads
    blob_upload = []
    failed_uploads = []

    # Define the backup location
    path = settings.arcgis.backup_location

    # Check if the backup location exists
    if not os.path.exists(path):
        error_message = f"The backup location '{path}' does not exist or is not accessible. Upload to Azure Blob Storage cannot proceed."
        logging.error(error_message)
        send_failure_email(settings, error_message, operation)
        return blob_upload

    connect_str = settings.azure.connection_string
    blob_service_client = BlobServiceClient.from_connection_string(connect_str)

    # Walk through the backup location recursively
    for root, dirs, files in os.walk(path):
        for filename in files:
            upload_file_path = os.path.join(root, filename)
            folder_name = os.path.relpath(root, path)
            blob_name = f"{filename}" if folder_name == '.' else f"{folder_name}/{filename}"
            blob_client = blob_service_client.get_blob_client(container=settings.azure.container_name, blob=blob_name)

            try:
                if blob_client.exists():
                    logging.info(f"Blob '{blob_name}' already exists in Azure Blob Storage. Deleting local file '{upload_file_path}' and skipping upload.")
                    if os.path.exists(upload_file_path):
                        os.remove(upload_file_path)
                        logging.info(f"Local file '{upload_file_path}' was deleted because the blob already exists in Azure Blob Storage.")
                    continue

                with open(upload_file_path, mode="rb") as data:
                    blob_client.upload_blob(data)

                logging.info(f"File '{blob_name}' was uploaded to Azure Blob Storage successfully.")
                blob_upload.append(blob_name)
                os.remove(upload_file_path)
                logging.info(f"Local file '{upload_file_path}' was deleted after successful upload.")

            except Exception as e:
                error_message = f"An error occurred while uploading file '{blob_name}' to Azure Blob Storage: {e}"
                logging.error(error_message)
                failed_uploads.append(upload_file_path)
                try:
                    send_failure_email(settings, error_message, operation)
                except Exception:
                    pass
                logging.warning(f"Skipping failed file '{upload_file_path}' and continuing with the next one.")
                continue

    if failed_uploads:
        logging.warning(f"The following files failed to upload to Azure Blob Storage: {failed_uploads}")

    if blob_upload:
        logging.info(f"Upload to Azure Blob Storage completed successfully. Total files uploaded: {len(blob_upload)}.")
    else:
        logging.info("No files were uploaded to Azure Blob Storage.")

    return blob_upload
