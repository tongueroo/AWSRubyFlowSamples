##
# Copyright 2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#  http://aws.amazon.com/apache2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
##

require 'aws/decider'
require_relative 'utils'
require_relative 'deployment_workflow'
include AWS::Flow

deployment_workflow_client = workflow_client($swf.client, $domain) { {:from_class => "DeploymentWorkflow"} }

puts "starting an execution..."
configuration_file = "./application_stack.yml"
workflow_execution = deployment_workflow_client.start_execution(configuration_file)
