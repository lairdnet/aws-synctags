# aws-sync-tags - Keep dependent resource tags in sync.
Maintaining tags across dependent resources provides accurate cost allocation reporting and tag based policy enforcement.

Whether its simple typos, revising tag values or adjusting standards, tags get out of sync. Because we never do things manually, this project will create a Lambda function to keep important tags in sync across resources. 

## Solution
This solution will create all the required dependencies for your Lambda function including IAM roles and policies, logs, a Cloudwatch Event Rules to trigger the Lambda function when EC2 resource tags are updated and an SNS topic and subscription so you can receive e-mail notifications on tag updates.

This project also aims to be a functional example of using the AWS CLI or AWS CloudFormation to create and manage the solution. A minimal set of resources, references and nesting are used in order to focus on the fundamentals of creating a solution that leverages a few key services of AWS. The Lambda function also demonstrates the use of the AWS SDK for Python (Boto 3).

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
This solution contains two directories with the commands and resources which produce the same results using either the AWS CLI or AWS CloudFormation.

cli - AWS CLI shell commands.
cfn - AWS CloudFormation template, Lambda function code and CloudFormation CLI commands.

In each method directory open the .txt file to review the commands to create, test and delete the solution resources.

.\cli\synctags-cli.txt

.\cfn\synctags-cfn-cli.txt

Review the comments and commands starting with the environment variable set commands. These variables define the configurable parameters of the solution.

```
set aws_profile=MY-AWS-PROFILE
set aws_accountid=000000000000
set aws_notifyemail=ME@EMAIL.COM
set aws_functiontest_instanceid=i-00000000000000000
set aws_default_region=us-east-1
set aws_nameprefix=synctags
set aws_synctagkeys=[\"Name\", \"BillingCode\", \"Application\", \"Environment\"]
```

| Variable  | Description  | Example |
|---|---|---|
|aws_profile   | Set the default profile for the AWS CLI credentials. See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html for more information.  | set aws_profile=my-default-profile  |
|aws_accountid   | Set your AWS account ID to be used in API calls. See https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html for more information. Use the command 'aws sts get-caller-identity' to view your account id using the AWS CLI.   | set aws_account=555500007777  |
|aws_notifyemail   | Used to create the initial SNS topic subscription to receive e-mails when tag synchronization updates are completed. See https://lairdnet-assets-public.s3.amazonaws.com/synctags-topic-email.jpg for an example of the e-mail notification message. | set aws_notifyemail=mytagsgotsynced@mydomain.com  |
|aws_functiontest_instanceid| CLI Invoke commands are provided to test both a synctagskeys No Match and Match condition. The AWS EC2 Instance ID provided here is used as the event instance. | set aws_functiontest_instanceid=i-01234567890abcdef|
|aws_default_region|Set the AWS CLI region, overriding the profile defined region. This is the region that cli commands will default do and where the solution will be deployed. See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html for more information.|set aws_default_region=us-west-2|
|aws_nameprefix|Resources created by this solution will be prefixed with this string for identification within your environment.|set aws_nameprefix=my-sync-tags-solution|
|aws_synctagskeys|List of tag keys that the solution should synchronize on child resources. Tag keys not in this list are ignored.|set aws_synctagkeys=[\"CostCenter\",\"App\"]|

Once you ahve set your parameter values based on your environment you can use the remaining commands in the .txt file specific for either the CLI or CloudFormation method to complete the solution deployment.

### Requirements
The commands and scripts in this solution assume you have the AWS CLI 1.x installed (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) and configured using named profiles (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html).

#### References
AWS CloudFormation: <https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html>
AWS Command Line Interface: <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html>
AWS SDK for Python (BOTO 3): <https://boto3.amazonaws.com/v1/documentation/api/latest/index.html>

