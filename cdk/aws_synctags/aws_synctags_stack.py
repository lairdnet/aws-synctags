import os
from aws_cdk import (
    aws_lambda as _lambda,
    aws_iam,
    aws_sns,
    aws_sns_subscriptions,
    aws_events,
    aws_events_targets,
    core
)

ACCOUNT=os.environ.get('aws_accountid', '111111111111')
REGION=os.environ.get('aws_default_region', 'us-east-1')
RESOURCE_NAME_PREFIX = os.environ.get('aws_nameprefix', 'cdk-synctags')
SYNCTAG_KEYS = os.environ.get('aws_synctagkeys', '[\"Name\", \"BillingCode\", \"Application\", \"Environment\"]')
NOTIFY_EMAIL = os.environ.get('aws_notifyemail', '')

class AwsSynctagsStack(core.Stack):

    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)


        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_iam/Role.html
        iamRole = aws_iam.Role(self, 'aws-synctags-role',
                            role_name=RESOURCE_NAME_PREFIX + '-role',
                            assumed_by=aws_iam.ServicePrincipal('lambda.amazonaws.com'),
                            path='/service-role/'
                            )

        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_lambda/Function.html
        lambdaHandler = _lambda.Function(self, 'aws-synctags-event-handler',
                                function_name=RESOURCE_NAME_PREFIX + '-event-handler',
                                code=_lambda.Code.asset('./lambda'),
                                handler='synctags.lambda_handler',
                                timeout=core.Duration.seconds(30),
                                runtime=_lambda.Runtime.PYTHON_3_7, 
                                role=iamRole)


        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_sns/Topic.html
        snsTopic = aws_sns.Topic(self, 'aws-synctags-topic',
                            topic_name=RESOURCE_NAME_PREFIX + '-topic',
                            display_name=RESOURCE_NAME_PREFIX + '-topic'
                            )  

        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_sns_subscriptions.html
        snsTopic.add_subscription(aws_sns_subscriptions.EmailSubscription(NOTIFY_EMAIL))

        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_iam/Role.html
        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_iam/PolicyStatement.html
        iamRole.attach_inline_policy(aws_iam.Policy(self,'aws-synctags-policy',
                                    policy_name=RESOURCE_NAME_PREFIX + '-role-policy',statements=[
                                            aws_iam.PolicyStatement(resources=[self.format_arn(service='logs', resource='*')],
                                            actions=['logs:CreateLogGroup']),
                                            aws_iam.PolicyStatement(resources=[self.format_arn(service='logs', resource='log-group', sep=':', resource_name='/aws/lambda/'+ RESOURCE_NAME_PREFIX + '-event-handler:*')],
                                            actions=['logs:CreateLogStream',
                                                    'logs:PutLogEvents']),
                                            aws_iam.PolicyStatement(resources=['*'],
                                            actions=['ec2:DescribeInstances',
                                                    'ec2:DescribeVolumes',
                                                    'ec2:CreateTags',
                                                    'ec2:DeleteTags',
                                                    'ec2:DescribeNetworkInterfaces',
                                                    'ec2:DescribeTags',
                                                    'ec2:DescribeSnapshots',
                                                    'ec2:DescribeAddresses']),
                                            aws_iam.PolicyStatement(resources=[snsTopic.topic_arn],
                                            actions=['sns:Publish',
							                        'sns:Subscribe']),
                                            aws_iam.PolicyStatement(resources=['*'],
                                            actions=['iam:ListAccountAliases'])
                                            ]
                                ))
        
        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_events.html
        eventRule = aws_events.Rule(self, 'aws-synctags-event-rule',
            rule_name=RESOURCE_NAME_PREFIX + '-event-rule',
            enabled=True,
            event_pattern=aws_events.EventPattern(source=['aws.tag'], detail_type=['Tag Change on Resource'], detail={'service':['ec2'],'resource-type':['instance']}),
            targets=[aws_events_targets.LambdaFunction(lambdaHandler)])

        #https://docs.aws.amazon.com/cdk/api/latest/python/aws_cdk.aws_lambda/Function.html#aws_cdk.aws_lambda.Function.add_permission
        #lambdaHandler.add_permission('aws-synctags-lambda-permission',
        #principal=aws_iam.ServicePrincipal('events.amazonaws.com'),
        #action='lambda:InvokeFunction',
        #source_arn=eventRule.rule_arn)

        lambdaHandler.add_environment('SyncTagKeys',SYNCTAG_KEYS)
        lambdaHandler.add_environment('NotifyTopicArn',snsTopic.topic_arn)

