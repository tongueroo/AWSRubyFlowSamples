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
require_relative 'cron_workflow'

# This code will terminate this program once all the workers and
#   activities have been terminated
if @domain.workflow_executions.with_status(:open).count.count > 0
  @domain.workflow_executions.with_status(:open).each(&:terminate)
end

# These are the initial parameters for the Simple Workflow
#
# @param job [Hash] information about the job that needs to be run. It
#   contains a cron string, the function to call (in activity.rb), and the function
#   call's arguments
# @param base_time [Time] time to start the cron workflow
# @param interval_length [Integer] how often to reset history (seconds)
job = { :cron => "* * * * *",  :func => :add, :args => [3,4]}

base_time = Time.now
interval_length = 121

# Create a workflow client and start the workflow
my_workflow_client =
  workflow_client(@swf.client, @domain) { { :from_class => "CronWorkflow" } }

puts "Starting an execution..."
workflow_execution = my_workflow_client.run(job, base_time, interval_length)
