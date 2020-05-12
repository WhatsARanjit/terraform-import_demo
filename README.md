# Terraform Import Example

#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Workflow](#workflow)
    * [Create an orphaned resource](#create-an-orphaned-resource)
    * [Import and orphaned resource](#import-and-orphaned-resource)
    * [Generate Terraform code](#generate-terraform-code)
    * [Run generated code](#run-generated-code)
    * [Destroy the resource](#destroy-the-resource)
1. [Demo Reset](#demo-reset)

## Overview

An example workflow for importing an unmanaged resource into Terraform state and generating the corresponding code.

## Requirements

* `terraform` version >= 0.12.0
* AWS credentials
* `jq`


## Workflow

### Create an orphaned resource

* First, start by creating an example VPC in AWS to play with:

```shell
cd examples/
terraform init
terraform apply -auto-approve
```

* Grab the VPC_ID for later:

```shell
export VPC_ID=$(terraform output -json | jq -r '.ARN.value' | rev | cut -d/ -f1 | rev)
```

### Import and orphaned resource

Let's move back to the main directory:

```shell
cd ..
```

* Now for all intents and purposes, working out of this directory, Terraform has no idea of any state
* To make a strong point, you can even consider deleting the `terraform.tfstate` and `terraform.tfstate.backup` files to simulate an event
* Attempt to import the VPC with the name `main`:

```shell
export TF_RESOURCE_NAME="main"
terraform import aws_vpc.$TF_RESOURCE_NAME $VPC_ID
```

* You'll see that Terraform is unhappy because there is no resource in code for `aws_vpc.main`
* This is kind of a chicken & egg problem
* So let's stub a resource:

```shell
cat << EOF > "./${TF_RESOURCE_NAME}.tf"
resource "aws_vpc" "${TF_RESOURCE_NAME}" {}
EOF
cat "${TF_RESOURCE_NAME}.tf"
```

* Now we have a stubbed resource
* Attempt to import the resource again:

```shell
terraform import aws_vpc.$TF_RESOURCE_NAME $VPC_ID
```

* Now Terraform is unhappy because the provider is not completely configured
* We have to supply the region information, which is not actually in the statefile itself:

```shell
export AWS_DEFAULT_REGION=us-east-1
```

* Now attempt to import the resource:

```shell
terraform import aws_vpc.$TF_RESOURCE_NAME $VPC_ID
```

### Generate Terraform code

* You can generate Terraform code from state like this:

```shell
terraform show -no-color > $TF_RESOURCE_NAME.tf
```

* We're overwriting the stub with real code
* Running the generated code from state should produce a no-changes apply:

```shell
terraform apply -auto-approve
```

**NOTE:** When running on a terminal, Terraform recognizes you are a human returns HCL.  When running inside of a script Terraform decides to return JSON instead.

### Run generated code

```shell
terraform apply -auto-approve
```

* We see that Terraform is unhappy because the code is specifying values for read-only attrbutes
* Remove to read-only attributes from the code, which are:
  * `arn`
  * `default_network_acl_id`
  * `default_route_table_id`
  * `default_security_group_id`
  * `dhcp_options_id`
  * `id`
  * `main_route_table_id`
  * `owner_id`
* Now try the code again:

```shell
terraform apply -auto-approve
```

### Destroy the resource

* Now that we have the resource under management and corresponding code, we can take it the end of its lifecycle:

```shell
terraform destroy -auto-approve
```

## Demo Reset

```shell
rm -f *.tf terraform.tfstate*
rm -f example/terraform.tfstate*
unset AWS_DEFAULT_REGION
```

