#!/bin/bash
set -e

echo "🏗️  Running Terraform Apply..."
cd terraform
terraform apply -auto-approve

echo "📝 Extracting IPs and Building Inventory..."
# Get the inventory string we built in Terraform outputs.tf
# We use -raw to get the text without quotes
INVENTORY_CONTENT=$(terraform output -raw ansible_inventory)

# Write it to the ansible folder
echo "[kijanikiosk]" > ../ansible/inventory.ini
echo "$INVENTORY_CONTENT" >> ../ansible/inventory.ini

echo "🛠️  Running Ansible Playbook..."
cd ../ansible
# We skip host key checking because LocalStack IPs are recycled
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i inventory.ini kijanikiosk.yml
