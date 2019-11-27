## Bolt Dynamic Inventory
1. How to connect to existing terraform resources using terraform plugin
1. How to apply and destroy resources with terraform module
1. How to query resource state in a plan


### Scenario
Web servers in front of a load balancer exist in us-west-2 data center. Instead I would like to have those running in us-east-2. Provision new web servers, configure them, add them to load balancer and remove them from us-west-2 


## Workflow
The web servers and load balancer are provisioned the `provision_and_deploy_stack` plan which applies terraform resources `aws_instance.load_balancer` and `aws_instance.web_servers` to the us-west-2 data center. It installs nginx and serves a web application on the provisioned web servers. Finally the load balancer is configured to run haproxy to load balance connection requests to the web applications.
```
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ bolt plan run webinar::provision_and_deploy_stack  --params @Boltdir/params/init_provision.json --inventoryfile Boltdir/empty_inventory.yaml
Starting: plan webinar::provision_and_deploy_stack
Starting: plan terraform::apply
Starting: task terraform::apply on localhost
Finished: task terraform::apply with 0 failures in 28.74 sec
Finished: plan terraform::apply in 28.78 sec
Starting: wait until available on ec2-34-221-146-16.us-west-2.compute.amazonaws.com, ec2-54-245-210-45.us-west-2.compute.amazonaws.com, ec2-54-212-170-172.us-west-2.compute.amazonaws.com
Finished: wait until available with 0 failures in 8.64 sec
Starting: plan webinar::configure_webservers
Starting: install puppet and gather facts on ec2-54-245-210-45.us-west-2.compute.amazonaws.com, ec2-54-212-170-172.us-west-2.compute.amazonaws.com
Finished: install puppet and gather facts with 0 failures in 37.01 sec
Starting: apply catalog on ec2-54-245-210-45.us-west-2.compute.amazonaws.com, ec2-54-212-170-172.us-west-2.compute.amazonaws.com
Finished: apply catalog with 0 failures in 14.29 sec
Finished: plan webinar::configure_webservers in 51.32 sec
Starting: plan webinar::configure_haproxy
Starting: install puppet and gather facts on ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Finished: install puppet and gather facts with 0 failures in 30.89 sec
Starting: apply catalog on ec2-34-221-146-16.us-west-2.compute.amazonaws.com
ec2-34-221-146-16.us-west-2.compute.amazonaws.com: Scope(Haproxy::Config[haproxy]): haproxy: The $merge_options parameter will default to true in the next major release. Please review the documentation regarding the implications.
Finished: apply catalog with 0 failures in 11.72 sec
Finished: plan webinar::configure_haproxy in 42.61 sec
Finished: plan webinar::provision_and_deploy_stack in 2 min, 12 sec
Plan completed successfully with no result
```
We build an inventoryfile to discover the newly created resources (inventory.yaml). We have organized this to group the web servers and load balancer.
```
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ bolt command run hostname -t web_servers
Started on ec2-54-245-210-45.us-west-2.compute.amazonaws.com...
Started on ec2-54-212-170-172.us-west-2.compute.amazonaws.com...
Finished on ec2-54-245-210-45.us-west-2.compute.amazonaws.com:
  STDOUT:
    ip-172-31-13-241
Finished on ec2-54-212-170-172.us-west-2.compute.amazonaws.com:
  STDOUT:
    ip-172-31-13-180
Successful on 2 nodes: ec2-54-245-210-45.us-west-2.compute.amazonaws.com,ec2-54-212-170-172.us-west-2.compute.amazonaws.com
Ran on 2 nodes in 0.65 sec
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ bolt command run hostname -t load_balancer
Started on ec2-34-221-146-16.us-west-2.compute.amazonaws.com...
Finished on ec2-34-221-146-16.us-west-2.compute.amazonaws.com:
  STDOUT:
    ip-172-31-7-229
Successful on 1 node: ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Ran on 1 node in 0.64 sec
```
The web servers have been configured to serve a web page that contains a message identifying them. We can curl the load balancer dns name and see the responses from each of the web servers as the load is alternated by the load balancer:
```
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ curl ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Hello from ec2-54-245-210-45.us-west-2.compute.amazonaws.com
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ curl ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Hello from ec2-54-212-170-172.us-west-2.compute.amazonaws.com
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ curl ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Hello from ec2-54-245-210-45.us-west-2.compute.amazonaws.com
```
Now we want to provision new web servers in the us-east-2 data center, add them to the load balancer and destroy the web servers in the us-west-2 data center. This is accomplished with the `migrate_webservers` plan. This plan provisions new servers in the east datacenter and installs our web app on the newly provisioned resources. The load balancer is updated to start sending requests to the servers in the east data center and finally the web servers in the west data center are destroyed.
```
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ bolt plan run webinar::migrate_webservers --params @Boltdir/params/migration.json
Starting: plan webinar::migrate_webservers
Starting: plan terraform::apply
Starting: task terraform::apply on localhost
Finished: task terraform::apply with 0 failures in 128.65 sec
Finished: plan terraform::apply in 2 min, 9 sec
Starting: wait until available on ec2-3-14-13-30.us-east-2.compute.amazonaws.com, ec2-3-134-86-241.us-east-2.compute.amazonaws.com
Finished: wait until available with 0 failures in 1.98 sec
Starting: plan webinar::configure_webservers
Starting: install puppet and gather facts on ec2-3-14-13-30.us-east-2.compute.amazonaws.com, ec2-3-134-86-241.us-east-2.compute.amazonaws.com
Finished: install puppet and gather facts with 0 failures in 32.23 sec
Starting: apply catalog on ec2-3-14-13-30.us-east-2.compute.amazonaws.com, ec2-3-134-86-241.us-east-2.compute.amazonaws.com
Finished: apply catalog with 0 failures in 13.26 sec
Finished: plan webinar::configure_webservers in 45.51 sec
Starting: plan webinar::configure_haproxy
Starting: install puppet and gather facts on ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Finished: install puppet and gather facts with 0 failures in 4.21 sec
Starting: apply catalog on ec2-34-221-146-16.us-west-2.compute.amazonaws.com
ec2-34-221-146-16.us-west-2.compute.amazonaws.com: Scope(Haproxy::Config[haproxy]): haproxy: The $merge_options parameter will default to true in the next major release. Please review the documentation regarding the implications.
Finished: apply catalog with 0 failures in 6.88 sec
Finished: plan webinar::configure_haproxy in 11.12 sec
Starting: plan terraform::destroy
Starting: task terraform::destroy on localhost
Finished: task terraform::destroy with 0 failures in 37.49 sec
Finished: plan terraform::destroy in 37.5 sec
Finished: plan webinar::migrate_webservers in 3 min, 45 sec
Plan completed successfully with no result
```
We can see that requests are routed to the newly provisioned servers in the east data center! 
```
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ curl ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Hello from ec2-3-14-13-30.us-east-2.compute.amazonaws.com
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ curl ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Hello from ec2-3-134-86-241.us-east-2.compute.amazonaws.com
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ curl ec2-34-221-146-16.us-west-2.compute.amazonaws.com
Hello from ec2-3-14-13-30.us-east-2.compute.amazonaws.com
```
Also included a plan to wipe everything clean to avoid aws charges. 
```
cas@cas-ThinkPad-T460p:~/working_dir/webinar$ bolt plan run webinar::destroy_everything --params @Boltdir/params/destroy.json
Starting: plan webinar::destroy_everything
Starting: plan terraform::destroy
Starting: task terraform::destroy on localhost
Finished: task terraform::destroy with 0 failures in 37.62 sec
Finished: plan terraform::destroy in 37.62 sec
Starting: plan terraform::destroy
Starting: task terraform::destroy on localhost
Finished: task terraform::destroy with 0 failures in 42.06 sec
Finished: plan terraform::destroy in 42.06 sec
Finished: plan webinar::destroy_everything in 1 min, 20 sec
Plan completed successfully with no result
```