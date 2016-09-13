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
            write_asset(f_in, f, 'text/javascript; charset=UTF-8', True)

def deploy_js(name):
    raw_name = "{0}.js".format(name)
    min_name = "{0}.min.js".format(name)
    web_dir = os.path.dirname(os.path.realpath(__file__))
    js_file = os.path.join(web_dir, raw_name)
    process = Popen(['uglifyjs', js_file], stdout=PIPE)
    (output, err) = process.communicate()
    exit_code = process.wait()
    if exit_code != 0:
        print("UglifyJS gave exit code of {0}".format(exit_code))
        exit(exit_code)
    write_asset(StringIO.StringIO(output), min_name, 'text/javascript; charset=UTF-8', False)
    invalidate('/{0}'.format(min_name));

def deploy_css(name):
    name = '{0}.css'.format(name)
    web_dir = os.path.dirname(os.path.realpath(__file__))
    css_file = os.path.join(web_dir, name)
    with open(css_file, 'r') as f_in:
        write_asset(f_in, name, 'text/css; charset=UTF-8', False)
    invalidate('/{0}'.format(name))

def deploy_img(img_name):
    web_dir = os.path.dirname(os.path.realpath(__file__))
    img_file = os.path.join(web_dir, img_name)
    with open(img_file, 'r') as f_in:
        write_asset(f_in, img_name, 'image/png', True)
    invalidate('/{0}'.format(img_name))

def invalidate(path):
    cloudfront_client.create_invalidation(
        DistributionId=CLOUDFRONT_ID,
        InvalidationBatch={
            'CallerReference': str(int(time.time())) + path,
            'Paths': {
                'Quantity': 1,
                'Items': [path]
            }
        })

def deploy_about():
    web_dir = os.path.dirname(os.path.realpath(__file__))
    files = [['about.html', 'about', 'text/html'],
             ['skippedbeats.png', 'image/png'],
             ['badday.png', 'image/png']]
    for f in files:
        path = os.path.join(web_dir, f[0])
        out_name = f[-2]
        content_type = f[-1]
        with open(path, 'r') as f_in:
            write_asset(f_in, out_name, content_type, False)
        invalidate("/{0}".format(out_name))

def write_asset(f_in, name, content_type, cache_forever):
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
        ContentType=content_type,
        ContentEncoding="gzip",
        ContentLength=len(gzipped_bytes))
    if cache_forever:
        kwargs['CacheControl'] = "max-age=31536000, public"
    s3client.put_object(**kwargs)

def deploy():
    deploy_about()
    deploy_external()
    deploy_js('index')
    deploy_js('session')
    deploy_css('session')
    deploy_img('lines.0.png')

if __name__ == '__main__':
    deploy()
