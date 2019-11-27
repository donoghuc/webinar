plan webinar::migrate_webservers(
  Hash $apply_new,
  Hash $destroy_old
){
  # Bring up new web servers
  run_plan('terraform::apply', $apply_new)

  # Discover new targets and add them to inventory
  $references = {
    '_plugin' => 'terraform',
    'dir' => '../terraform',
    'resource_type' => 'aws_instance.web_servers',
    'state' => $apply_new['state_out'],
    'target_mapping' => {
      'name' => 'public_dns',
      'config' => {
        'ssh' => {
          'host' => 'public_ip'
        }
      }
    }
  }
  $lookup_targets = resolve_references($references)
  $new_web_servers = $lookup_targets.map |$target| {
    Target.new($target)
  }

  # Ensure targets are reachable
  wait_until_available($new_web_servers, 'wait_time' => 60)

  # Configure new web_servers
  run_plan('webinar::configure_webservers', 'servers' => $new_web_servers)

  # Add new servers to load balancer (and remove the old)
  run_plan('webinar::configure_haproxy', {'load_balancer' => 'load_balancer', 'balance_members' => $new_web_servers})

  # Destroy old web servers
  run_plan('terraform::destroy', $destroy_old)
}
