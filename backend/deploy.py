#!/usr/bin/env python

import zipfile
import os
import os.path
import boto3
import tempfile

def make_zip(zip_file):
    backend_dir = os.path.dirname(os.path.realpath(__file__))
    canvasdeps_dir = os.path.join(backend_dir, 'canvasdeps')
    count = 0
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as deployment:
        for f in os.listdir(backend_dir):
            if f.endswith('.js'):
                deployment.write(os.path.join(backend_dir, f), f)
        node_modules_dir = os.path.join(backend_dir, 'node_modules')
        for root, dirs, files in os.walk(node_modules_dir):
            for f in files:
                full_path = os.path.join(root, f)
                node_modules_relpath = os.path.relpath(full_path, node_modules_dir)
                if not (node_modules_relpath.startswith('aws-sdk') or
                        node_modules_relpath.startswith('canvas')):
                    relpath = os.path.relpath(full_path, backend_dir)
                    deployment.write(full_path, relpath)
                    count += 1
                    if count % 100 == 0:
                        print "At {0} files".format(count)
        add_to_zip(deployment, canvasdeps_dir, count)

def add_to_zip(zip_file, base_dir, count):
    for root, dirs, files in os.walk(base_dir):
        for f in files:
            full_path = os.path.join(root, f)
            relpath = os.path.relpath(full_path, base_dir)
            zip_file.write(full_path, relpath)
            count += 1
            if count % 100 == 0:
                print "At {0} files".format(count)

def update_function(client, function_name, zip_file_bytes):
    client.update_function_code(
        FunctionName=function_name,
        ZipFile=zip_file_bytes,
        Publish=True)

def update_all():
    zip_file_bytes = None
    with tempfile.TemporaryFile() as temp_file:
        make_zip(temp_file)
        temp_file.seek(0)
        zip_file_bytes = temp_file.read()
    client = boto3.client('lambda')
    function_names = ["HeartSessionResponder"]
    for function_name in function_names:
        print "Updating {0} with {1} bytes".format(function_name, len(zip_file_bytes))
        update_function(client, function_name, zip_file_bytes)

if __name__ == '__main__':
    update_all()
