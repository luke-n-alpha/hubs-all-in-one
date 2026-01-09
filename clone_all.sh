#!/bin/bash
set -ex
cd "$(dirname "$0")"

# Load the environment file based on the first parameter
ENV_FILE="$1"

# Check if the environment configuration file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file '$ENV_FILE' not found."
  exit 1
fi

# Source the environment configuration file
source "$ENV_FILE"

# Source functions.sh
source ./functions.sh "$ENV_FILE"

copy_ssl() {
  local src="$1"
  local dest="$2"

  if [ -r "$src" ]; then
    cp -L "$src" "$dest"
  else
    sudo cp -L "$src" "$dest"
    sudo chown "$(id -u):$(id -g)" "$dest"
  fi
}

clone_repo() {
  local repo_url="$1"
  local repo_dir="$2"

  if [ -d "$repo_dir" ] && [ -z "$(ls -A "$repo_dir")" ]; then
    rm -rf "$repo_dir"
  fi

  if [ ! -d "$repo_dir" ]; then
    git clone "$repo_url" "$repo_dir"
  fi
}

# If the second parameter is not provided or is 'dialog', execute dialog
if [ -z "$2" ] || [ "$2" == "dialog" ]; then
  # dialog
  clone_repo "https://github.com/luke-n-alpha/dialog.git" "dialog"

  mkdir -p ./dialog/certs
  rm -rf ./dialog/certs/*.pem
  copy_ssl "$SSL_CERT_FILE" ./dialog/certs/cert.pem
  copy_ssl "$SSL_KEY_FILE" ./dialog/certs/key.pem
  cp $PERMS_PUB_FILE ./dialog/certs/perms.pub.pem
fi

# If the second parameter is not provided or is 'hubs', execute everything except dialog
if [ -z "$2" ] || [ "$2" == "hubs" ]; then
  # hubs
  clone_repo "https://github.com/luke-n-alpha/hubs.git" "hubs"

  mkdir -p ./hubs/certs
  rm -rf ./hubs/certs/*.pem

  echo $SSL_CERT_FILE 
  echo $SSL_KEY_FILE

  cp -L $SSL_CERT_FILE ./hubs/certs/cert.pem
  copy_ssl "$SSL_CERT_FILE" ./hubs/certs/cert.pem
  copy_ssl "$SSL_KEY_FILE" ./hubs/certs/key.pem

  echo "Copying and replacing variables in hubs/env.template to create hubs/.env"
  cp_and_replace ./hubs/env.template ./hubs/.env
  echo "Copying and replacing variables in hubs/nginx.conf.template to create hubs/nginx.conf"
  cp_and_replace ./hubs/nginx.conf.template ./hubs/nginx.conf
  echo "Copying and replacing variables in hubs/admin/env.template to create hubs/admin/.env"
  cp_and_replace ./hubs/admin/env.template ./hubs/admin/.env
  echo "Copying and replacing variables in hubs/admin/nginx.conf.template to create hubs/admin/nginx.conf"
  cp_and_replace ./hubs/admin/nginx.conf.template ./hubs/admin/nginx.conf

  # reticulum
  clone_repo "https://github.com/luke-n-alpha/reticulum.git" "reticulum"

  mkdir -p ./reticulum/certs
  rm -rf ./reticulum/certs/*.pem
  copy_ssl "$SSL_CERT_FILE" ./reticulum/certs/cert.pem
  copy_ssl "$SSL_KEY_FILE" ./reticulum/certs/key.pem
  cp $PERMS_PRV_FILE ./reticulum/certs/perms.prv.pem

  rm -rf ./reticulum/.env
  cp_and_replace ./reticulum/env.template ./reticulum/.env

  add_env_var_to_file "LOGGING_URL" "./reticulum/.env" "LOGGING_URL=\${LOGGING_URL}"
  cp_and_replace ./reticulum/dev.exs.template ./reticulum/config/dev.exs
  add_env_var_to_file "LOGGING_URL" "./reticulum/config/dev.exs" "config :ret, :logging_url, \\\"\${LOGGING_URL}\\\""
  cp_and_replace ./reticulum/runtime.exs.template ./reticulum/config/runtime.exs
  cp_and_replace ./reticulum/.vscode/launch.json.template ./reticulum/.vscode/launch.json

  # spoke
  clone_repo "https://github.com/luke-n-alpha/spoke.git" "spoke"

  mkdir -p ./spoke/certs
  rm -rf ./spoke/certs/*.pem
  copy_ssl "$SSL_CERT_FILE" ./spoke/certs/cert.pem
  copy_ssl "$SSL_KEY_FILE" ./spoke/certs/key.pem

  cp_and_replace ./spoke/env.template ./spoke/.env.prod
  cp_and_replace ./spoke/nginx.template ./spoke/nginx.conf

  # Copy and replace variables in nginx.template for proxy
  cp_and_replace ./proxy/nginx.template ./proxy/nginx.conf
  cp_and_replace ./postgrest/postgrest.template ./postgrest/postgrest.conf

fi
