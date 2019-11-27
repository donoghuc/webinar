plan webinar::configure_webservers(
  TargetSpec $servers,
  String $site_content = "Hello"
){
  apply_prep($servers)
  apply($servers) {
    # Install nginx
    package {'nginx':
      ensure => present,
    }
    # Serve some content that identifies host
    file { '/var/www/html/index.html': 
      content =>  "${site_content} from ${$trusted['certname']}\n",
      ensure => file,
    }
    # Start the service
    service { 'nginx':
      ensure => 'running',
      enable => 'true', 
      require => Package['nginx'],
    }
  }
}
