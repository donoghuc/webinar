plan webinar::configure_haproxy(
  TargetSpec $load_balancer,
  TargetSpec $balance_members
){
  # Make target data available across apply boundry
  $member_data = get_targets($balance_members).map |Target $target| {
    {'host_name' => $target.name, 'public_ip' => $target.host}
  }

  # Configure haproxy to spread load over web servers
  apply_prep($load_balancer)
  apply($load_balancer){
    include haproxy
    haproxy::listen { 'nginx':
      collect_exported => false,
      ipaddress => $facts['ipaddress'],
      ports => '80',
    }

    $member_data.each |Integer $index, Hash $data| {
      haproxy::balancermember { "lb_${index}":
        listening_service => 'nginx', 
        server_names => $data['host_name'],
        ipaddresses => $data['public_ip'],
        ports => '80',
        options => 'check',
      }
    }
  }
}
