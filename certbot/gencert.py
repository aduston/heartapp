import os
import os.path
import subprocess
from aws_settings import ACCESS_KEY, SECRET_KEY, BUCKET_NAME_0, CF_DIST_ID_0, \
    BUCKET_NAME_1, CF_DIST_ID_1

myenv = os.environ.copy()
myenv["AWS_ACCESS_KEY_ID"] = ACCESS_KEY
myenv["AWS_SECRET_ACCESS_KEY"] = SECRET_KEY

sites = [(CF_DIST_ID_0, BUCKET_NAME_0, "adamsheart.com"),
         (CF_DIST_ID_1, BUCKET_NAME_1, "www.adamsheart.com")]

for dist_id, bucket, domain in sites:
    cmd = [os.path.join(os.path.dirname(__file__), "venv/bin/certbot"),
           "--agree-tos", "-a", "certbot-s3front:auth",
           "--certbot-s3front:auth-s3-bucket", bucket, "-i",
           "certbot-s3front:installer", 
           "--logs-dir=/Users/aduston/certbotlogs",
           "--renew-by-default", "--text",
           "--certbot-s3front:installer-cf-distribution-id",
           dist_id, "-d", domain]
    subprocess.call(cmd, env=myenv)
