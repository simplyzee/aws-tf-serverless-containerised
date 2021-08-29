# aws-tf-serverless-containerised

A terraform repository that manages a lambda function and an ECS container that runs in AWS Fargate.

## Installation

AWS Access keys are required for terraform to work.

```
export AWS_ACCESS_KEY_id=[the-key]
export AWS_SECRET_ACCESS_KEY=[secret-key]
```

With the above set, the user can now authenticate and run terraform plan or apply.

`terraform init` - will initialise the modules and the local tf environment
`terraform plan` - will produce a plan
`terraform apply` - will apply TF changes into AWS

