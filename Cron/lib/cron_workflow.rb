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
require_relative 'cron_activity'

require 'parse-cron'

class CronWorkflow
  extend Workflows

  # workflow options
  workflow :run do
    {
      :version => "1",
      :execution_start_to_close_timeout => 3600,
      :task_list => $task_list
    }
  end

  # activity client declaration
  activity_client(:activity) { { :from_class => "CronActivity" } }

  # Determines the schedule times for the job that lie within the current interval and creates a list of
  #   those for scheduling by the worker_client
  #
  # @param job [Hash] information about the job that needs to be run. It
  #   contains a cron string, the function to call (in activity.rb), and the function
  #   call's arguments
  # @param base_time [Time] time to start the cron workflow
  # @param interval_length [Integer] how often to reset history (seconds)
  # @return [Array] list of times at which to invoke the job
  def get_schedule_times(job, base_time, interval_length)
    return [] if job.empty?
    # generate a cron_parser for each job
    cron_parser = CronParser.new(job[:cron])

    # store the times at which this job will be called within the given interval
    times_to_schedule = []
    next_time = cron_parser.next(base_time)
    while(base_time <= next_time and next_time < base_time + interval_length) do
      times_to_schedule.push((next_time - base_time + 0.5).to_i)
      next_time = cron_parser.next(next_time)
    end

    # return the list of times at which the job needs to be scheduled
    times_to_schedule
  end

  # Main method in the workflow, determines the times at which to run the job and then schedules them
  #
  # @param (see #get_schedule_times)
  def run(job, base_time = Time.now, interval_length = 121)

    # get a list of times at which the job needs to be scheduled
    times_to_schedule = get_schedule_times(job, base_time, interval_length)
    # schedule all invocations of the job asynchronously
    times_to_schedule.each do |time|
      async_create_timer(time) {
        activity.run_job(job[:func], *job[:args])
      }
    end

    # update base_time to move to the next interval of time
    base_time += interval_length
    create_timer(interval_length)

    # sets flag so that this workflow will be called again once complete (after
    #   the interval is over)
    #
    # @param (see #get_schedule_times)
    continue_as_new(job, base_time, interval_length) do |options|
      options.execution_start_to_close_timeout = 3600
      options.task_list = $task_list
      options.tag_list = []
      options.version = "1"
    end
  end

end

worker = WorkflowWorker.new(@swf.client, @domain, $task_list, CronWorkflow)
# Start the worker if this file is called directly from the command
# line, to prevent it from being run if it's required in
worker.start if __FILE__ == $0
