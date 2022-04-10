# az-tfpoc
 A simple terraform deployment to Azure. The following resources are defined:
 - One resource group, "az-tf-poc"
 - One vnet, "tf-poc-vnet" with five subnets:
 - Three RHEL virtual machines:
   - Two DS1v2 RHEL machines in an availability set in subnet 1, each with 256gb disks
   - One DS1v2 RHEL machine in subnet 3 with Apache listening on port 80, with a 64gb OS disk and an additional 32gb data disk
 - An Azure Bastion host for connecting to all three machines
 - An Azure Key Vault for storing the virtual machine admin credentials
 - An Azure Load Balancer with a public IP, listening on port 80 and forwarding requests to the Apache server on subnet 3
 - Network security groups associated with subnets:
   - Sub1 for the RHEL machines
   - Sub3 for the RHEL Apache server
   - AzureBastionSubnet for the Bastion host
 - A storage account with network rules limiting access to the vnet only 

 
# Prerequisites
- Terraform and AZ CLI must both be installed on your local machine
- Your AAD identity must have at least contributor level permissions for the subscription you will be deploying into

# To run
First, login to Azure with the AZ CLI:

> az login

Once you have authenticated to Azure, initialize Terraform from the az-tfpoc directory

> terraform init

This code defaults to AustraliaCentral for the region, since I have a requirement to use a specific VM size that was available there. To specify a different region, append the region variable to your plan or apply commands:

> terraform plan -var="region=foo"

> terraform apply -far="region=foo"

It may take some time for Terraform to install the provider files. Once Terraform is initialized, run plan to validate your deployment 
> terraform plan

The output will indicate what resources will be created. If you are satisfied with the plan, you can run apply
> terraform apply

Some of the resources take time to deploy, in particular the Key Vault, Bastion, Virtual Machines, and Storage account. If any of these timeout, you may run terraform apply again without issue.

# Testing
Once the deployment is complete, navigate to the Azure portal and select the "frontend-pip" public IP address. Navigating to that IP address in the browser will take you to the default Apache server index page.

To connect directly to any of the Virtual Machines, you may use Azure Bastion.

First, navigate to the key vault resource. It will have a randomly generated name (they are required to be globally unique) with a prefix of "poc-kv-". On the left hand menu, click Secrets. Terraform will have added an access policy allowing you to view secrets, so the list will be displayed.

Select the "vm-admin-credentials" secret and click on the current version. You can copy the secret to your clipboard without revealing it, or choose to show it in the browser. The secret value is the password, and the content-type is the username.

After retreiving the admin credentials, navigate back to any of the virtual machines in the Azure Portal and click Connect at the top of the screen. On the drop down that appears, select Bastion. In the Bastion blade that appears, first uncheck the box for "Open in new window", all it does is cause problems. Enter your admin credentials and click connect. After some time, the terminal will appear.

Once inside one of the Virtual Machines you may test SSH between any of them using the same credentials, since we installed a custom script extension to allow password authentication for SSH.




