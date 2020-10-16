## Provisioning SonarQube Server on an Azure Ubuntu 18.04 LTS VM with Terraform

------

## Instructions 

-  **Install Azure CLI** 

Linux:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

Windows (Powershell):

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
```

MacOS

```bash
brew update && brew install azure-cli
```

- **Authenticate to your Azure account**: 

(You should get your subscription ID after running it. You will need to save it for the next step)

```
az login
```

- **Create an Azure Service Principal** (`<subscription_id>` should be substituted for the ID you got previously)

```bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<subscription_id>"
```

You will get some values you will need to save somewhere

- **Log in with the Service Principal**(The `name`, `password`, and `tenant` values from the previous step will be used here.)

```bash
az login --service-principal -u <service_principal_name> -p "<service_principal_password>" --tenant "<service_principal_tenant>"
```

- **Set your Azure subscription** (useful if you have multiple accounts)

```bash
az account set --subscription="<subscription_id>"
```

- **Create a storage account for the Terraform State storage** (Substitute the `$` variables with names of your choosing)

```bash
az group create --name $RESOURCE_GROUP_NAME --location $location
```

```bash
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
```

```bash
az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv.
```

 This will give you an access key `$ACCOUNT_KEY` you will need to keep for the next step.

```bash
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY
```

- **Rename the** `terraform.tfvars.example` **to** `terraform.tfvars` **and edit** `backend.tf` **to contain the required values**

- **Running the Script**

```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply -auto-approve
```

Wait for a few minutes and then you can visit the IP Address displayed from Terraform apply on a web browser

<img src="https://github.com/code2exe/tf-azure_ubuntu-sonarqube/blob/develop/sonarqube.png" width="100%">

- **Destroy the infrastructure**

```bash
terraform destroy -auto-approve
```

