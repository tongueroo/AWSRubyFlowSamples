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

class DeploymentActivity
  extend AWS::Flow::Activities

  activity :deploy_database, :deploy_app_server, :deploy_web_server, :deploy_load_balancer do
    {
      :version => "1.0",
      :default_task_list => $activity_task_list,
      :default_task_schedule_to_start_timeout => 30,
      :default_task_start_to_close_timeout => 30,
    }
  end

  def deploy_database
    puts "deploying database"
    "jdbc:foo/bar"
  end

  def deploy_app_server(data_sources)
    puts "deploying app server"
    "http://baz"
  end

  def deploy_web_server(data_sources, app_servers)
    puts "deploying web server"
    "http://webserver"
  end

  def deploy_load_balancer(web_server_urls)
    puts "deploying load balancer"
    "http://myweb.com"
  end

end

activity_worker = AWS::Flow::ActivityWorker.new($swf.client, $domain, $activity_task_list, DeploymentActivity) { {:use_forking => false} }
activity_worker.start if __FILE__ == $0
