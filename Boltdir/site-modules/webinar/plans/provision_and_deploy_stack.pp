plan webinar::provision_and_deploy_stack(
  Hash $terraform_params
){
  # Provision load balancer and web servers in single data center
  run_plan('terraform::apply', $terraform_params)
  $web_server_ref = {
    '_plugin' => 'terraform',
    'dir' => '../terraform',
    'resource_type' => 'aws_instance.web_servers',
    'state' => 'west_init_state.tfstate',
    'target_mapping' => {
      'name' => 'public_dns',
      'config' => {
        'ssh' => {
          'host' => 'public_ip'
        }
      }
    }
  }
  # Look up web servers
  $lookup_web_servers = resolve_references($web_server_ref)
  $web_server_targets = $lookup_web_servers.map |$target| {
    Target.new($target)
  }

  $load_balancer_ref = {
    '_plugin' => 'terraform',
    'dir' => '../terraform',
    'resource_type' => 'aws_instance.load_balancer',
    'state' => 'west_init_state.tfstate',
    'target_mapping' => {
      'name' => 'public_dns',
      'config' => {
        'ssh' => {
          'host' => 'public_ip'
        }
      }
    }
  }
  # look up load_balancer
  $lookup_load_balancer = resolve_references($load_balancer_ref)
  $load_balaner_targets = $lookup_load_balancer.map |$target| {
    Target.new($target)
  }

  # Ensure connection
  wait_until_available($load_balaner_targets + $web_server_targets, 'wait_time' => 100)

  # Configure new web_servers
  run_plan('webinar::configure_webservers', 'servers' => $web_server_targets)

  # Add new servers to load balancer (and remove the old)
  run_plan('webinar::configure_haproxy', {'load_balancer' => $load_balaner_targets, 'balance_members' => $web_server_targets })
}
