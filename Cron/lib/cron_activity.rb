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

class CronActivity
  extend Activities

  # activity options
  activity :run_job, :add, :sum do
    {
      :default_task_list => $task_list,
      :version => "1",
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30,
    }
  end

  # Takes in a function to call and executes it
  # @param func [lambda] function that will get called by the activity
  # @return [void] returns whatever the function call returns
  def run_job(func, *args)
    if self.method(func).arity > 1
      self.send(func, *args)
    else
      self.send(func, args)
    end
  end

  # add your functions here

  def add(a,b)
    puts "Adding these numbers #{a}, #{b}"
    a + b
  end

end

activity_worker =
  ActivityWorker.new(@swf.client, @domain, $task_list, CronActivity) { {:use_forking => false } }

# Start the worker if this file is called directly from the command
# line, to prevent it from being run if it's required in
activity_worker.start if __FILE__ == $0
