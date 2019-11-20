#!/usr/bin/env python3

from aws_cdk import core

from aws_synctags.aws_synctags_stack import AwsSynctagsStack

app = core.App()
AwsSynctagsStack(app, "aws-synctags")

app.synth()
