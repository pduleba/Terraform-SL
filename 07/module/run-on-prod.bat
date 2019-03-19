set TF_LOG_PATH=./prod/prod.log
set TF_LOG=DEBUG
terraform plan -var-file="./../terraform.tfvars" -var-file="./prod/prod.tfvars" -state="./prod/prod.tfstate"