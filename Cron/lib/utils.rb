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
include AWS::Flow

# Sets up domain, task list, etc. for SWF implementation
$CRON_DOMAIN = "CronSample"

config_file = File.open('credentials.cfg') { |f| f.read }
AWS.config(YAML.load(config_file))

@swf = AWS::SimpleWorkflow.new

begin
  @domain = @swf.domains.create($CRON_DOMAIN, "10")
rescue AWS::SimpleWorkflow::Errors::DomainAlreadyExistsFault => e
  @domain = @swf.domains[$CRON_DOMAIN]
end

# Set up the workflow/activity worker
$task_list = "cron_task_list"
