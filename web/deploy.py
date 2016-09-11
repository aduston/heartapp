#!/usr/bin/env python

import boto3
import time
import StringIO
import os
import os.path
import gzip
import shutil
from subprocess import Popen, PIPE

S3_BUCKET = 'adamsheart-site'
CLOUDFRONT_ID = 'E2QVTW8XZXK8E7'

s3client = boto3.client('s3')
cloudfront_client = boto3.client('cloudfront')

def deploy_external():
    web_dir = os.path.dirname(os.path.realpath(__file__))
    external_dir = os.path.join(web_dir, 'external')
    for f in os.listdir(external_dir):
        full_name = os.path.join(external_dir, f)
        with open(full_name, 'r') as f_in:
            write_js(f_in, f, True)

def deploy_index():
    web_dir = os.path.dirname(os.path.realpath(__file__))
    index_file = os.path.join(web_dir, 'index.js')
    process = Popen(['uglifyjs', index_file], stdout=PIPE)
    (output, err) = process.communicate()
    exit_code = process.wait()
    if exit_code != 0:
        print("UglifyJS gave exit code of {0}".format(exit_code))
        exit(exit_code)
    write_js(StringIO.StringIO(output), 'index.min.js', False)
    cloudfront_client.create_invalidation(
        DistributionId=CLOUDFRONT_ID,
        InvalidationBatch={
            'CallerReference': str(int(time.time())),
            'Paths': {
                'Quantity': 1,
                'Items': ['/index.min.js']
            }
        })

def write_js(f_in, name, cache_forever):
    gzipped = StringIO.StringIO()
    with gzip.GzipFile(fileobj=gzipped, mode='w') as f_out:
        shutil.copyfileobj(f_in, f_out)
    gzipped_bytes = gzipped.getvalue()
    print("Uploading {0} with length {1}".format(name, len(gzipped_bytes)))
    kwargs = dict(
        ACL='public-read',
        Body=gzipped_bytes,
        Bucket=S3_BUCKET,
        Key=name,
        ContentType='text/javascript; charset=UTF-8',
        ContentEncoding="gzip",
        ContentLength=len(gzipped_bytes))
    if cache_forever:
        kwargs['CacheControl'] = "max-age=31536000, public"
    s3client.put_object(**kwargs)

def deploy():
    deploy_external()
    deploy_index()

if __name__ == '__main__':
    deploy()
