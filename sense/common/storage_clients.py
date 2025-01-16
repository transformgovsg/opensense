from typing import Dict, Union, Any

import boto3
from chainlit.data import BaseStorageClient
from chainlit.logger import logger


class NullStorageClient(BaseStorageClient):
    """
    Implements interface without doing anything
    """

    def __init__(self):
        logger.info("NullStorageClient initialized")

    async def upload_file(
        self,
        object_key: str,
        data: Union[bytes, str],
        mime: str = "application/octet-stream",
        overwrite: bool = True,
    ) -> Dict[str, Any]:
        return {"object_key": object_key, "url": "https://nope.gov.sg"}


RESULTS_EXPIRY_TIME_IN_SECONDS = 3600


# This class is being redeclared because `chainlit` import both azure
# and boto3 directly into the same module. We cannot partially import
# just the S3 Storage Client from chainlit.
#
# Thus, we copied over the class.
class S3StorageClient(BaseStorageClient):
    """
    Class to enable Amazon S3 storage provider
    """

    def __init__(self, bucket: str):
        self.bucket = bucket
        self.client = boto3.client("s3")

    async def upload_file(
        self,
        object_key: str,
        data: Union[bytes, str],
        mime: str = "application/octet-stream",
        overwrite: bool = True,
    ) -> dict[str, Any]:
        self.client.put_object(
            Bucket=self.bucket, Key=object_key, Body=data, ContentType=mime
        )
        url = self.client.generate_presigned_url(
            "get_object",
            Params={"Bucket": self.bucket, "Key": object_key},
            ExpiresIn=RESULTS_EXPIRY_TIME_IN_SECONDS,
        )
        return {"object_key": object_key, "url": url}
