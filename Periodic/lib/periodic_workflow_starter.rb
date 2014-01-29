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
require_relative 'periodic_workflow'
include AWS::Flow

my_workflow_client = workflow_client($swf.client, $domain) { {:from_class => "PeriodicWorkflow"} }

puts "starting an execution..."
running_options = PeriodicWorkflowOptions.new(10,false,20,40)
activity_name ="do_some_work"
prefix_name ="PeriodicActivity"
activity_args=["parameter1"]
$workflow_execution = my_workflow_client.start_execution(running_options, prefix_name, activity_name, *activity_args)
