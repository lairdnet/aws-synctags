# aws-synctags - Keep dependent resource tags in sync.

Maintaining tags across dependent resources provides accurate cost allocation reporting and tag based policy enforcement.

Whether its simple typos, revising tag values or adjusting standards, tags get out of sync. Because we never do things manually, this project will create a Lambda function to keep important tags in sync across resources.  

## Solution

This solution will create all the required dependencies for your Lambda function including IAM roles and policies, logs, a Cloudwatch Event Rules to trigger the Lambda function when EC2 resource tags are updated and an SNS topic and subscription so you can receive e-mail notifications on tag updates.

This project also aims to be a functional example of using the AWS CLI, AWS CloudFormation, AWS Cloud Development Kit or HashiCorp Terraform to create and manage the solution. A minimal set of resources, references and nesting are used in order to focus on the fundamentals of creating a solution that leverages a few key services of AWS. The Lambda function also demonstrates the use of the AWS SDK for Python (Boto 3).

The following resources will be created as part of this solution.

1. IAM Role with inline policy for Lambda execution.
2. Lambda function written in Python.
3. Cloudwatch Event Rule with Lambda invoke permissions.
4. SNS Topic and e-mail subscription.

The following diagram of the Lambda function designer shows the referenced resources.

![Lambda Function Designer](https://lairdnet-assets-public.s3.amazonaws.com/synctags-designer.jpg "Lambda Function Designer")

The following diagram shows the Resources created using the CloudFormation method.

![CloudFormation Resources](https://lairdnet-assets-public.s3.amazonaws.com/synctags-cfn-resources.jpg "CloudFormation Resources")

## Get Started

This solution contains four directories with the commands and resources which produce the same results using either the AWS CLI, AWS CloudFormation, AWS Cloud Development Kit (CDK) and HashiCorp Terraform.

cli - AWS CLI  
cfn - AWS CloudFormation  
cdk - AWS CDK  
tf - HashiCorp Terraform  

In each method directory open the *-cli.txt file to review the commands to create, test and delete the solution resources.

[.\cli\synctags-cli.txt](/cli/synctags-cli.txt)  
[.\cfn\synctags-cfn-cli.txt](/cfn/synctags-cfn-cli.txt)  
[.\cdk\synctags-cdk-cli.txt](/cdk/synctags-cdk-cli.txt)  
[.\tf\synctags-tf-cli.txt](/tf/synctags-tf-cli.txt)  

Review the comments and commands starting with the environment variable set commands. These variables define the configurable parameters of the solution.

```batch
set AWS_PROFILE=MY-AWS-PROFILE
set AWS_DEFAULT_REGION=us-east-1
set aws_accountid=000000000000
set aws_notifyemail=ME@EMAIL.COM
set aws_functiontest_instanceid=i-00000000000000000
set aws_nameprefix=synctags
set aws_synctagkeys=[\\"Name\\", \\"BillingCode\\", \\"Application\\", \\"Environment\\"]
set aws_cfnbucket=%aws_nameprefix%-cfn-bucket
set TF_VAR_terraform_cloud_org=my-tf-cloud-org
set TF_VAR_terraform_cloud_workspace=my-tf-cloud-workspace
```

| Variable  | Description  | Example |
|---|---|---|
|AWS_PROFILE   | Set the default profile for the AWS CLI credentials. See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html for more information.  | set AWS_PROFILE=my-default-profile  |
|AWS_DEFAULT_REGION|Set the AWS CLI region, overriding the profile defined region. This is the region that cli commands will default to and where the solution will be deployed. See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html for more information.|set AWS_DEFAULT_REGION=us-west-2|
|aws_accountid   | Set your AWS account ID to be used in API calls. See https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html for more information. Use the command 'aws sts get-caller-identity' to view your account id using the AWS CLI.   | set aws_account=555500007777  |
|aws_notifyemail   | Used to create the initial SNS topic subscription to receive e-mails when tag synchronization updates are completed. See https://lairdnet-assets-public.s3.amazonaws.com/synctags-topic-email.jpg for an example of the e-mail notification message. | set aws_notifyemail=mytagsgotsynced@mydomain.com  |
|aws_functiontest_instanceid| CLI Invoke commands are provided to test both a synctagskeys No Match and Match condition. The AWS EC2 Instance ID provided here is used as the event instance. | set aws_functiontest_instanceid=i-01234567890abcdef|
|aws_nameprefix|Resources created by this solution will be prefixed with this string for identification within your environment.|set aws_nameprefix=my-sync-tags-solution|
|aws_synctagskeys|List of tag keys that the solution should synchronize on child resources. Tag keys not in this list are ignored.|set aws_synctagkeys=[\"CostCenter\",\"App\"]|
|aws_cfnbucket|CloudFormation solution only. Specifies the name of the S3 bucket to create to source the Lambda function code file.|set aws_cfnbucket=1343234-cfn-bucket|  
|TF_VAR_terraform_cloud_org|Terraform solution only. Specifies the Terraform Cloud oranization ID. See https://www.terraform.io/docs/cloud/index.html|set TF_VAR_terraform_cloud_org=MY-ORG|  
|TF_VAR_terraform_cloud_workspace|Terraform solution only. Specifies the Terraform Cloud workspace name. See https://www.terraform.io/docs/cloud/getting-started/workspaces.html|set TF_VAR_terraform_cloud_workspace=my-workspace|

Once you have set your parameter values based on your environment you can use the remaining commands in the .txt file specific for the CLI, CloudFormation or Terraform method to complete the solution deployment.

### Terraform Considerations

The SNS topic subscription created as part of this solution is not natively supported by Terraform. To workaround this the provided template leverages a local-exec provisioner to execute the AWS CLI commands to create the subscription. The SNS topic subscription is an unmanaged resource in Terraform. Additionally, if you choose to use Terraform Cloud for state management and execution the AWS CLI is not available on the Terraform Cloud worker nodes. Although software can be installed on the worker nodes as part of the local-exec command, enabling sudo is only available in Terraform Cloud Enterprise. Given these conditions the SNS topic subscription will not be created if you configure the Terraform solution to use Terraform Cloud as the remote backend.

### LINUX / OSX Considerations

If you are deploying the solution from a Linux or OSX based workstation the same dependency requirements exist however there are three changes required to configure the solution.

1. Modify the environment variable statements to use "export" in place of "set", i.e. "export AWS_PROFILE=my-default-profile"
2. Modify any environment variables references in command line statements, i.e. AWS CLI, to use the $variable syntax, i.e. $AWS_PROFILE
3. If you are using the AWS CDK solution, update the cdk.json file in the cdk directory to specify "python3" in place of "python", i.e.

    ```json
    {
        "app": "python3 app.py"
    }
    ```

### Requirements

The commands and scripts in this solution assume you have the AWS CLI 1.x installed (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) and configured using named profiles (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html). 

If using the AWS CDK solution, the commands and scripts assume you have installed Python 3.x (https://www.python.org/downloads/).  

If using the Terraform solution, the commands and scripts assume you have installed HashiCorp Terraform (https://www.terraform.io/downloads.html). If using remote state management with Terraform Cloud you have created a user token and configured your local Terraform CLI config (https://www.terraform.io/docs/cloud/migrate/index.html), created a workspace (https://www.terraform.io/docs/cloud/getting-started/workspaces.html) and configured workspace environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY.  

### Costs

Using this solution will incur AWS service charges. AWS Lambda and AWS CloudWatch Events are charged at a per execution bill rate. Example, the current CloudWatch Events rate is $1.00 per million events in the US East region. AWS Lambda costs are based on number of requests and memory allocated to the function. Example, the current rate is $.20 per million requests and $0.0000166667 per Gigabyte-second. See https://aws.amazon.com/lambda/pricing/ and https://aws.amazon.com/cloudwatch/pricing/ for more pricing information. The monthly costs for this solution will vary based on the number of tag change events that occur in the target account.

#### References

AWS CloudFormation: <https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html>  
AWS Command Line Interface: <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html>  
AWS SDK for Python (BOTO 3): <https://boto3.amazonaws.com/v1/documentation/api/latest/index.html>  
AWS Cloud Development Kit: <https://docs.aws.amazon.com/cdk/latest/guide/home.html>  
AWS CDK Python Reference: <https://docs.aws.amazon.com/cdk/api/latest/python/index.html>  
HashiCorp Terraform: <https://www.terraform.io/docs/index.html>  

readme
