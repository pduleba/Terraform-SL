set TF_LOG_PATH=./dev/dev.log
set TF_LOG=DEBUG
terraform plan -var-file="./../terraform.tfvars" -var-file="./dev/dev.tfvars" -state="./dev/dev.tfstate"