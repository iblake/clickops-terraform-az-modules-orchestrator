# Demo: Minimal Azure Orchestrator Example

This example shows the simplest possible deployment using the orchestrator: **1 Resource Group, 1 VNet, 1 Subnet, 1 VM**.

## 🚀 Quickstart

1. **Prepare your SSH key**
   - Edit `compute.tfvars.json` and replace `YOUR_PUBLIC_KEY_HERE` with your actual SSH public key.

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Plan the deployment**
   ```bash
   terraform plan -var-file="iam.tfvars.json" -var-file="networking.tfvars.json" -var-file="compute.tfvars.json"
   ```

4. **Apply the configuration**
   ```bash
   terraform apply -var-file="iam.tfvars.json" -var-file="networking.tfvars.json" -var-file="compute.tfvars.json"
   ```

5. **Access your VM**
   - Use the Azure Portal or CLI to find the private IP of the VM
   - Connect via SSH:  
     `ssh azureuser@<PRIVATE_IP>`

6. **Destroy the resources (when done)**
   ```bash
   terraform destroy -var-file="iam.tfvars.json" -var-file="networking.tfvars.json" -var-file="compute.tfvars.json"
   ```

## 📄 Files
- `iam.tfvars.json`: Resource group definition
- `networking.tfvars.json`: VNet and subnet definition
- `compute.tfvars.json`: VM definition

## 📝 Notes
- This is a minimal working example for demos and MVPs.
- You can extend it by adding more subnets, VMs, or modules as needed.
- All resources are eligible for the Azure free tier (Standard_B1s VM, basic storage, etc.).
