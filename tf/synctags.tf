// provider
variable "aws_default_region" {
    default = "us-east-1"
}
variable "aws_profile" {
    default = "default"
}

provider "aws" {
  region  = var.aws_default_region
  profile = var.aws_profile
}

// input variables
variable "resource_name_prefix" {
    type = string
    default = "synctags"
	description = "Prefix for all resources."
}
variable "sync_tag_keys" {
    type = string
    default = "[\"Name\", \"BillingCode\", \"Application\", \"Environment\"]"
	description = "Array of tag keys to synchronize."
}
variable "notification_email" {
    type = string
    default = ""
	description = "Email address for default notification subscription."
}
variable "terraform_backend_remote" {
    type=bool
    default = false
}
locals{
    iam_role_name = join("",[var.resource_name_prefix,"-role"])
    iam_role_policy_name = join("",[var.resource_name_prefix,"-policy"])
    lambda_name = join("",[var.resource_name_prefix,"-event-handler"])
    topic_name = join("",[var.resource_name_prefix,"-topic"])
    eventrule_name = join("",[var.resource_name_prefix,"-event-rule"])
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "archive_file" "lambda_zip" {
    type        = "zip"
    source_file  = "${path.module}/synctags.py"
    output_path = "${path.module}/synctags.zip"
    depends_on = [local_file.source_file]
}

resource "local_file" "source_file" {
    content     = <<EOF
import boto3 
import os

def lambda_handler(event, context): 
 
   accountname = boto3.client('iam').list_account_aliases()['AccountAliases'][0]
   topicarn = os.environ["NotifyTopicArn"]
   sync_tag_keys = os.environ["SyncTagKeys"] 
   instancename = '' 
   
   ec2_resource = boto3.resource('ec2') 
   ec2_client = boto3.client('ec2')
   sns_client = boto3.client('sns') 
 
   try: 
 
	   eventname = event['detail-type'] 
	   detail = event['detail'] 
 
	   if eventname == 'Tag Change on Resource': 
			 
		   if detail['service'] == 'ec2' and detail['resource-type'] == 'instance': 
 
			   changedtags = detail['changed-tag-keys'] 
			   resources = event['resources'][0].split('/') 
			   instanceid = resources[len(resources) - 1] 
				 
			   synctags = [t for t in changedtags or [] if t in sync_tag_keys] 
			   if not synctags: 
				   print("info: no matching changed tags") 
				   return 
				 
			   instance = ec2_resource.Instance(instanceid) 
 
			   tags = [t for t in instance.tags or [] if t['Key'] in sync_tag_keys] 
			   if not tags: 
				   print("info: no matching instance tags") 
				   return 
 
			   for vol in instance.volumes.all(): 
				   vol.create_tags(Tags=tags) 
				   snapshots = ec2_client.describe_snapshots(Filters=[{'Name':'volume-id','Values':[vol.id]}])['Snapshots']
				   for snap in snapshots:
				     snapshot = ec2_resource.Snapshot(snap['SnapshotId']) 
				     snapshot.create_tags(Tags=tags)

			   for eni in instance.network_interfaces: 
				   eni.create_tags(Tags=tags) 
				   
			   addresses = ec2_client.describe_addresses(Filters=[{'Name':'instance-id','Values':[instanceid]}])['Addresses']
			   for addr in addresses:
			     address = ec2_resource.VpcAddress(addr['AllocationId'])
			     ec2_client.create_tags(Resources=[addr['AllocationId']],Tags=tags)

			   for tag in instance.tags: 
				   if 'Name' in tag['Key']: 
					   instancename = tag['Value'] 
  
			   print('success: updated child resource tags for instance ' + instancename)
			   
			   subject = 'Tags Update Event - ' + accountname + ' - ' + instancename 
			   message = 'Instance Name: ' + instancename + '\r\rTags:\r' + str(instance.tags) + '\r\rEvent Detail:\r' + str(event) 
			 
			   response = sns_client.publish( 
				   TopicArn=topicarn,Message=message,Subject=subject 
			   ) 
			 
	   return True 
   except Exception as e: 
	   print(e) 
	   return False    			  
EOF
    filename = "${path.module}/synctags.py"
}

resource "aws_iam_role_policy" "iam_role_policy" {
  name = local.iam_role_policy_name
  role = aws_iam_role.iam_role_for_lambda.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.resource_name_prefix}-event-handler:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeVolumes",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:DescribeSnapshots",
                "ec2:DescribeAddresses"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish",
                "sns:Subscribe"
            ],
            "Resource": "${aws_sns_topic.sns_topic.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListAccountAliases"
            ],
            "Resource": "*"
        }					
    ]
}
EOF
}

resource "aws_iam_role" "iam_role_for_lambda" {
  name = local.iam_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
    path = "/service-role/"

}

resource "aws_sns_topic" "sns_topic"{
    name = local.topic_name
}

/*
//sns topic subscription protocol email currently not supported, see
//https://www.terraform.io/docs/providers/aws/r/sns_topic_subscription.html
//
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
//creating using null_resource, won't be state managed
*/
resource "null_resource" "sns_topic_subscription" {
  provisioner "local-exec" {
    command = var.terraform_backend_remote?"echo Running in Terraform Cloud, awscli is unsupported. SNS topic subscription not created. > ${data.template_file.sns_topic_subscription_log.rendered}":"aws sns subscribe --topic-arn ${aws_sns_topic.sns_topic.arn} --protocol email --notification-endpoint ${var.notification_email} --profile ${var.aws_profile} > ${data.template_file.sns_topic_subscription_log.rendered}"
  }
}

data "template_file" "sns_topic_subscription_log" {
  template = "${path.module}/sns_topic_subscription.log"
}

data "local_file" "sns_topic_subscription" {
  filename = "${data.template_file.sns_topic_subscription_log.rendered}"
  depends_on = [null_resource.sns_topic_subscription]
}

resource "aws_lambda_function" "lambda_function" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = local.lambda_name
  role          = aws_iam_role.iam_role_for_lambda.arn
  handler       = "synctags.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime = "python3.7"
  timeout = 30
  environment {
    variables = {
	    NotifyTopicArn = aws_sns_topic.sns_topic.arn
		SyncTagKeys = var.sync_tag_keys      
    }
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_event_rule.arn
  
}

resource "aws_cloudwatch_event_rule" "cloudwatch_event_rule" {
  name        = local.eventrule_name
  is_enabled = "true"

  event_pattern = <<PATTERN
{
    "source":["aws.tag"],
    "detail-type":["Tag Change on Resource"],
    "detail":{
        "service":["ec2"],
        "resource-type":["instance"]
        }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "cloudwatch_event_target" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_event_rule.name
  target_id = "1"
  arn       = aws_lambda_function.lambda_function.arn
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = data.aws_region.current.name
}

output "lambda_arn" {
    value = aws_lambda_function.lambda_function.arn
}

output "role_arn" {
    value = aws_iam_role.iam_role_for_lambda.arn
}

output "topic_arn" {
    value = aws_sns_topic.sns_topic.arn
}

output "event_rule_arn" {
    value = aws_cloudwatch_event_rule.cloudwatch_event_rule.arn
}

output "topic_subscription_cli_output" {
    value = data.local_file.sns_topic_subscription.content
}