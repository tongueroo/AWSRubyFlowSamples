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

require_relative 'utils'

class ErrorReportingActivity
  extend AWS::Flow::Activities

  activity :report_failure do
    {
      :version => "1.0",
      :default_task_list => $error_activity_task_list,
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30,
    }
  end

  def report_failure(e)
    workflow_execution = activity_execution_context.workflow_execution
    puts "Run Id:" + workflow_execution.run_id + ", Failure in periodic task:" + e.backtrace.to_s
  end

end

activity_worker = AWS::Flow::ActivityWorker.new($swf.client, $domain, $error_activity_task_list,  ErrorReportingActivity) { {:use_forking => false} }

activity_worker.start if __FILE__ == $0
