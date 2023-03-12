#!/bin/bash

if [[ -n $(terraform state list) ]]; then
  echo "Terraform resources have already been created. Please use './wg-server stop' to delete them first."
  exit 1
fi

# Runs the AWS command to retrieve the list of available regions
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Converts the text string into an array
regions_array=($regions)

# Displays the list of available regions
echo "Available AWS regions:"
for (( i=0; i<${#regions_array[@]}; i++ )); do
    echo "$i. ${regions_array[$i]}"
done

# Prompts the user to select a region
read -p "Select a region (enter the number): " region_index

# Checks if the selected index is valid
if ! [[ "$region_index" =~ ^[0-9]+$ ]] || [ "$region_index" -ge ${#regions_array[@]} ] || [ "$region_index" -lt 0 ]; then
    echo "Invalid selection. Please select a valid number."
    exit 1
fi

# Retrieves the selected region from the array
selected_region=${regions_array[$region_index]}

# Displays the selected region
echo "You have selected the region ${selected_region}."

# Writes the selected region to the local variable in the main.tf file
sed -i "s/region = \"[^\"]*\"/region = \"$selected_region\"/" main.tf

echo "The region has been updated in main.tf."

terraform init
terraform apply -auto-approve
wireguard_client_config=$(terraform output -raw client_config 2>&1)
if [ $? != 0 ]; then
    echo "Terraform Wireguard Client Config Output Failed, check your Terraform Configuration"
    exit 1
fi
sudo mkdir -p /etc/wireguard
sudo sh -c "echo '$wireguard_client_config' > /etc/wireguard/wg0.conf"

# Get the instance ID of the EC2 instance
ec2_instance_id=$(terraform output -raw instance_id 2>&1)
if [ $? != 0 ]; then
    echo "Terraform EC2 Instance ID Output Failed, check your Terraform Configuration"
    exit 1
fi

# Get the region of the EC2 instance
ec2_region=$(terraform output -raw region 2>&1)
if [ $? != 0 ]; then
    echo "Terraform EC2 Region Output Failed, check your Terraform Configuration"
    exit 1
fi

# Wait for the instance to reach the running state
echo "Waiting for EC2 instance to reach the running state..."
aws ec2 wait instance-status-ok --instance-ids "$ec2_instance_id" --region "$ec2_region"

# Check if Wireguard Server is running before starting the client
while ! aws ssm send-command \
        --document-name "AWS-RunShellScript" \
        --instance-ids "$ec2_instance_id" \
        --parameters commands="sudo systemctl is-active --quiet wg-quick@wg0.service" \
        --query "CommandInvocations[0].CommandPlugins[0].Output" \
        --output text \
        --region "$ec2_region" | grep -q "None"; do
    echo "Waiting for Wireguard Server to start..."
    sleep 5
done

echo "Starting Wireguard Client..."
sudo systemctl start wg-quick@wg0.service
sudo systemctl status wg-quick@wg0.service
echo "Wireguard Client has been started."
