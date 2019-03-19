set TF_LOG_PATH=./test/test.log
set TF_LOG=DEBUG
terraform plan -var-file="./../terraform.tfvars" -var-file="./test/test.tfvars" -state="./test/test.tfstate"