#!/bin/bash

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [[ -n $(terraform state list 2>/dev/null) ]]; then
  echo "Stoping Wireguard..."
  sudo systemctl stop wg-quick@wg0.service
  echo "Wireguard has been stopped."
  echo "Deleting Terraform resources..."
  terraform destroy -auto-approve
  echo "Terraform resources have been destroyed."
  exit 0
else
  echo "Terraform resources have already been destroyed."
  exit 1
fi

