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

require 'yaml'

require_relative 'utils'
require_relative './deployment_activity'
require_relative './deployment_types'

class DeploymentWorkflow
  extend AWS::Flow::Workflows

  workflow :deploy do
    {
      :version => "1.0",
      :task_list => $workflow_task_list,
      :execution_start_to_close_timeout => 120,
    }
  end

  activity_client(:deployment_activities) { {:from_class => "DeploymentActivity"} }

  def deploy(configuration_file)
    application_stack_data = YAML.load_file configuration_file
    components_data = application_stack_data["application_stack"]["components"]

    #create databases
    databases_data = components_data["database"]
    databases = Hash.new
    databases_data.each do|database_data|
      id = database_data["id"].to_sym
      host = database_data["host"]
      database = create_database(host)
      databases[id] = database
    end

    #create app servers
    app_servers_data = components_data["app_server"]
    app_servers = Hash.new
    app_servers_data.each do|app_server_data|
      id = app_server_data["id"].to_sym
      host = app_server_data["host"]
      #retrive the dependent databases
      dependent_databases = []
      database_ids = app_server_data["database"]
      database_ids.each do |database_id|
        if databases.has_key?(database_id.to_sym)
          dependent_databases << databases[database_id.to_sym]
        else
          raise ArgumentError, "the dependent database(#{database_id}) of app server(#{id}) does not exist"
        end
      end

      app_server = create_app_server(host, dependent_databases)
      app_servers[id]=app_server
    end

    #create web servers
    web_servers_data = components_data["web_server"]
    web_servers = Hash.new
    web_servers_data.each do|web_server_data|
      id = web_server_data["id"].to_sym
      host = web_server_data["host"]
      #retrieve the dependent databases
      dependent_databases = []
      database_ids = web_server_data["database"]
      database_ids.each do |database_id|
        if databases.has_key?(database_id.to_sym)
          dependent_databases <<databases[database_id.to_sym]
            else
                raise ArgumentError, "the dependent database(#{database_id}) of web server(#{id}) does not exist"
            end
        end

        #retrieve the dependent app servers
        dependent_app_servers=[]
        app_server_ids = web_server_data["app_server"]
        app_server_ids.each do |app_server_id|
            if app_servers.has_key?(app_server_id.to_sym)
                dependent_app_servers << app_servers[app_server_id.to_sym]
            else
                raise ArgumentError, "the dependent app server(#{app_server_id}) of web server(#{id}) does not exist"
            end
        end

        web_server = create_web_server(host, dependent_databases, dependent_app_servers )
        web_servers[id] = web_server
    end


    load_balancers_data = components_data["load_balancer"]
    load_balancers = Hash.new
    load_balancers_data.each do |load_balancer_data|
        id = load_balancer_data["id"].to_sym
        host = load_balancer_data["host"]
        #retrieve the dependent web servers
        web_server_ids = load_balancer_data["web_server"]
        dependent_web_servers=[]
        web_server_ids.each do |web_server_id|
            if web_servers.has_key?(web_server_id.to_sym)
                dependent_web_servers << web_servers[web_server_id.to_sym]
            else
                raise ArgumentError, "the dependent web server(#{web_server_id}) of load balancer(#{id}) does not exist"
            end

        end
        load_balancer = create_load_balancer(host, dependent_web_servers)
        load_balancers[id.to_sym] = load_balancer
    end

    # create frontend component
    frontend_name = application_stack_data["application_stack"]["frontend_component"]["name"]
    frontend_id = application_stack_data["application_stack"]["frontend_component"]["id"]

    case frontend_name
    when "database"
        frontend_component = databases[frontend_id.to_sym]
    when "app server"
        frontend_component = app_servers[frontend_id.to_sym]
    when "web server"
        frontend_component = web_servers[frontend_id.to_sym]
    when "load balancer"
        frontend_component = load_balancers[frontend_id.to_sym]
    end
    if frontend_component==nil
        raise ArgumentError, "the specified frontend component does not exist"
    end
    components = []
    components += databases.values
    components += app_servers.values
    components += web_servers.values
    components += load_balancers.values

    application_stack = ApplicationStack.new(components, frontend_component, deployment_activities)
    application_stack.deploy

  end

  def create_load_balancer(host, webservers)
    LoadBalancer.new(host, webservers)
  end

  def create_app_server(host, databases)
    AppServer.new(host, databases)
  end

  def create_web_server(host, databases, app_servers)
    WebServer.new(host, databases, app_servers)
  end

  def create_database(host)
    Database.new(host)
  end

end

worker = AWS::Flow::WorkflowWorker.new($swf.client, $domain, $workflow_task_list, DeploymentWorkflow)

worker.start if __FILE__ == $0
