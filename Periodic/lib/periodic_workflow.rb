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
require_relative "./periodic_activity"
require_relative "./error_reporting_activity"
require_relative "./periodic_workflow_options"

class PeriodicWorkflow
  extend AWS::Flow::Workflows

  workflow :start_periodic_workflow do
    {
      :version => "1.0",
      :task_list => $workflow_task_list,
      :execution_start_to_close_timeout => 120,
    }
  end

  activity_client(:activity) { {:from_class => "PeriodicActivity"} }
  activity_client(:error_report){ {:from_class => "ErrorReportingActivity"}  }


  def start_periodic_workflow(running_options, prefix_name, activity_name, *activity_args)
    @periodic_workflow_options = running_options
    @periodic_workflow_clock = decision_context.workflow_clock
    start_time = @periodic_workflow_clock.replay_current_time_millis

    error_handler do |t|
      t.begin do
        call_activity_periodically(start_time, prefix_name, activity_name, *activity_args)
      end

      t.rescue AWS::Flow::ActivityTaskFailedException do |e|
        error_report.report_failure(e)
      end

      t.ensure do
        seconds_left = @periodic_workflow_options.complete_after_seconds-
          (@periodic_workflow_clock.replay_current_time_millis - start_time)
        if (seconds_left > 0)
          next_running_options = PeriodicWorkflowOptions.new(
                                                             running_options.execution_period_seconds,
                                                             running_options.wait_for_activity_completion,
                                                             running_options.continue_as_new_after_seconds, seconds_left)

          continue_as_new( next_running_options, prefix_name, activity_name,*activity_args)
        end
      end

    end

  end

  def call_activity_periodically(start_time, prefix_name, activity_name, *activity_args)
    current_time = @periodic_workflow_clock.replay_current_time_millis
    duration = current_time - start_time
    if(duration < @periodic_workflow_options.continue_as_new_after_seconds)

      activity_future = activity.send_async("#{activity_name}", *activity_args ) do
        {
          :activity_name => "#{prefix_name}",
        }
      end

      timer_future = create_timer_async(@periodic_workflow_options.execution_period_seconds)

      if(@periodic_workflow_options.wait_for_activity_completion)
        wait_for_all(activity_future, timer_future)
      else
        wait_for_all(timer_future)
      end

      #recursive call to start activity periodically
      call_activity_periodically(start_time, prefix_name, activity_name, *activity_args)

    end

  end
end

workflow_worker = AWS::Flow::WorkflowWorker.new($swf.client, $domain, $workflow_task_list, PeriodicWorkflow)

workflow_worker.start if __FILE__ == $0
