#!/bin/sh
set -ex
cd "$(dirname "$0")"
THISDIR=$(pwd)
# Load the .env file based on the current directory
cd ..

# Get the environment file from the first parameter
ENV_FILE="$1"

# Check if the environment file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file '$ENV_FILE' not found."
  exit 1
fi

# Source the environment file
source "$ENV_FILE"

cd $THISDIR

touch error.log
touch access.log

docker rm -f proxy || true
docker run --log-opt max-size=10m --log-opt max-file=3 -d --restart=always --name proxy --network haio \
    -p 4080:4080 \
    -p 5000:5000 \
    -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf \
    -v $SSL_CERT_FILE:/etc/nginx/certs/cert.pem \
    -v $SSL_KEY_FILE:/etc/nginx/certs/key.pem \
    -v $(pwd)/error.log:/var/log/nginx/error.log \
    -v $(pwd)/access.log:/var/log/nginx/access.log \
    nginx:stable-alpine

docker logs proxy

