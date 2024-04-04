import logging
import boto3
from io import BytesIO
from PIL import Image
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(f"event: {event}")
    logger.info(f"context: {context}")

    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = event["Records"][0]["s3"]["object"]["key"]

    thumbnail_bucket = "jjaimesesteban-thumbnail-image-bucket"
    thumbnail_name, thumbnail_ext = os.path.splitext(key)
    thumbnail_key = f"{thumbnail_name}_thumbnail{thumbnail_ext}"

    logger.info(f"Bucket name: {bucket}, file name: {key}, Thumbnail Bucket name: {thumbnail_bucket}, file name: {thumbnail_key}")

    s3_client = boto3.client('s3')

    # Below snippet of code will Load and open image from S3
    file_byte_string = s3_client.get_object(Bucket=bucket, Key=key)['Body'].read()
    img = Image.open(BytesIO(file_byte_string))
    logger.info(f"Size before compression: {img.size}")

    # Below snippet of code will Generate thumbnail
    img.thumbnail((500,500), Image.ANTIALIAS)
    logger.info(f"Size after compression: {img.size}")

    # Below snippet of code will Dump and save image to S3
    buffer = BytesIO()
    img.save(buffer, "JPEG")
    buffer.seek(0)

    sent_data = s3_client.put_object(Bucket=thumbnail_bucket, Key=thumbnail_key, Body=buffer)

    if sent_data['ResponseMetadata']['HTTPStatusCode'] != 200:
        raise Exception('Failed to upload image {} to bucket {}'.format(key, bucket))

    return event