class quantum (
  $log_verbose       = 'False',
  $log_debug         = 'False',
  $bind_host         = '0.0.0.0',
  $bind_port         = '9696',
  $auth_type         = undef,
  $auth_host         = 'localhost',
  $auth_port         = '35357',
  $auth_protocol     = 'http',
  $auth_version      = '2.0',
  $keystone_user     = 'quantum',
  $keystone_password = undef,
  $region            = 'RegionOne',
  $public_address    = undef,
  $admin_address     = undef,
  $internal_address  = undef,
) inherits quantum::params {

  file { '/etc/quantum/quantum.conf':
    ensure  => present,
    owner   => 'quantum',
    group   => 'quantum',
    mode    => '0644',
    content => template('quantum/quantum.conf.erb'),
    require => Package[$::quantum::params::package_name],
  }

  package { $::quantum::params::package_name:
    ensure => latest,
  }

  service { $::quantum::params::service_name:
    enable  => true,
    ensure  => running,
    require => Package[$::quantum::params::package_name],
  }

  # This is a hack. Most likely a bug in the Ubuntu package
  file { '/usr/lib/python2.7/dist-packages/bin/nova-dhcpbridge':
    type   => link,
    target => '/usr/bin/nova-dhcpbridge',
  }

  # I don't think Essex/Quantum/Keystone work together
  if auth_type == 'keystone' {
    Keystone_user_role["${keystone_user}@service"] ~> Service <| name == 'quantum-server' |>
    keystone_user { $keystone_user:
      ensure   => present,
      password => $keystone_password,
    }
  
    keystone_user_role { "${keystone_user}@services":
      ensure => present,
      roles  => 'admin',
    }
  
    keystone_service { $keystone_user:
      ensure      => present,
      type        => 'network',
      description => 'Quantum Networking Service',
    }
  
    keystone_endpoint { $keystone_user:
      ensure       => present,
      region       => $region,
      public_url   => "http://${public_address}:${bind_port}/",
      admin_url    => "http://${admin_address}:${bind_port}/",
      internal_url => "http://${internal_address}:${bind_port}/",
    }
  }
}
