# Load/Stress Testing

We have two servers to deal with the load testing of the app (loadtest1 and loadtest2). The first one is where we have the app running and the other is a simple instance that will be responsible for firing the requests to loadtest1.

## Concepts

We are using a ruby gem to generate/run JMeter test plans. All tasks have the params `count` and `loop`. `count` is the number of threads (simultaneous users) we want to use and `loop` is how many times the requests should be fired.

When you execute the rake task, it will generate a JMeter test plan (extension .jmx) and execute it. Results are outputted to jmeter.jtl fileand it also generates a log file. The results should be loaded on JMeter with the graph wanted.

Another thing to note about the gem is that we could be using the [flood.io](https://flood.io/) service to execute the tests and provide reports with the exact code we have.

## Tasks

We have a set of rake tasks under the namespace `stress` to deal with the load/stress testing of the app.
Some tasks depends on other ones and some are standalone. They execute a JMeter test plan, as mentioned before.

### Main tasks (JMeter)

The two main tasks that run JMeter are:

#### navigate_app

This one just navigates through the basic app links and get the response time for each link. To run it
you just need to specify a valid login/password and a real mission that is set on the app.

#### sms_messages

Fires the specified amount of sms messages to a certain mission. This task is dependant of the task
`create_msgs_signature_file` because it needs valid msgs to submit to the server. To run it, first execute the dependant task and then provide the mission name and sms incoming token. Also note that you should provide for the loops param the amount of messages you have on the generated file.

### Additional tasks

#### create_msgs_signature_file

Generates a file with several valid sms parameters. Currently, it's for a determined form with 10 questions in a certain order... check [stress_sms_helper](https://github.com/thecartercenter/nemo/blob/load_test_and_optimizations/lib/task_helpers/stress_sms_helper.rb#L44). It's use is to have different random responses to be submitted to a form via the `sms_messages` task.

#### deploy_tasks

This copies the main tasks to the loadtest2 server along with the generated file of random valid responses.

#### load_sms_messages_in_db

Quick implementation to insert a lot of responses for a form on the server database (e.g 10m). It was implemented with some hardcoded values, so it still needs changes to be usable for any form.

## Running the tests

Just go to the loadtest2 server and execute the desired rake task. Results will be outputted on the jmeter.jtl file.

## Checking results

After executing the tasks on the loadtest2 server, you will need to get the results file and open it on JMeter in order to see the results in an appropriate way. There, you can choose the kind of graph you want to view the information.
