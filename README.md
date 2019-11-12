# aws-sync-tags - Keep dependent resource tags in sync.
Maintaining tags across dependent resources provides accurate cost
allocation tag reporting and tag based policy enforcement.

Typos, changing tag values and adjusting standards often leave tags
out of sync and because we never do things manually this project will
create a Lambda function to keep important tags in sync. All necessary
dependencies including IAM roles, policies, Cloudwatch Event Rules are
created. An SNS topic and default subscription are also added so you
can receive e-mail notifications on tag sync updates.

This project also aims to be a functional simplified example of using the 
AWS CLI and AWS CloudFormation to create and manage the solution. A
minimal amount of resources, references and nesting are used to focus
on the fundamentals of creating a solution that leverages key services
of AWS.

The following resources will be created as part of this solution.

1. IAM Role with inline policy for Lambda execution.
2. SNS Topic and e-mail subscription.
3. Lambda function (Python).
4. Cloudwatch Event Rule with Lambda invoke permissions.

## Get Started
This solution contains two source directories which produces the same results
using two different methods.

cli - Shell (Windows) and AWS CLI commands.
cfn - AWS Cloudformation template, dependencies and Cloudformation CLI commands.
	
### Requirements
The commands and scripts in this solution assume you have the AWS CLI 1.x
installed (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) and 
configured using named profiles (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html).