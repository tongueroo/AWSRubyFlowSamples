# AWS Flow Framework for Ruby Samples

## Prerequisites

The following prerequisites must be installed to use the Amazon Flow Framework for Ruby Samples:

* [The AWS Flow Framework for Ruby][aws-flow]
To install, at the command-line prompt, type:

        gem install aws-flow

* The "parse-cron" gem to run the Cron Sample
To install, at the command-line prompt, type:

        gem install parse-cron

## Running the Samples

First, you'll need to set your aws credentials. In the credentials.cfg file(aws-config.txt for HelloWorld), simply replace MY_ACCESS_KEY_ID and MY_SECRET_ACCESS_KEY with your own AWS access keys.

In order to run these samples, run the activity and workflow files, and then run the starter.

So, for the Booking sample:

    ruby booking_activity.rb &
    ruby booking_workflow.rb &
    ruby booking_workflow_starter.rb

For the HelloWorld sample:

    ruby hello_activity.rb &
    ruby hello_workflow.rb &
    ruby hello_world.rb

For the Periodic sample:

    ruby periodic_activity.rb &
    ruby error_reporting_activity.rb &
    ruby periodic_workflow.rb &
    ruby periodic_workflow_starter.rb

For the Cron sample:

    ruby cron_activity.rb &
    ruby cron_workflow.rb &
    ruby cron_starter.rb

For the Deployment sample:

    ruby deployment_activity.rb &
    ruby deployment_workflow.rb &
    ruby deployment_workflow_starter.rb
