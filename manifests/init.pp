class quantum (
  $keystone_password,
  $quantum_settings       = false,
  $quantum_dhcp_settings  = false,
  $keystone_enabled       = true,
  $keystone_tenant        = 'services',
  $keystone_user          = 'quantum',
  $keystone_auth_host     = 'localhost',
  $keystone_auth_port     = '35357',
  $keystone_auth_protocol = 'http',
  $dhcp_enabled           = true,
  $package_ensure         = 'latest',
  $enabled                = true,
) {

  include quantum::params

  package { 'quantum':
    name   => $::quantum::params::package_name,
    ensure => $package_ensure,
  }

  package { 'python-cliff':
    name   => $::quantum::params::cliff_name,
    ensure => latest,
  }

  File {
    ensure  => present,
    owner   => 'quantum',
    group   => 'quantum',
    mode    => '0644',
    require => Package[$::quantum::params::package_name],
    notify  => Service[$::quantum::params::service_name],
  }

  file { $::quantum::params::quantum_conf: }
  file { $::quantum::params::quantum_paste_api_ini: }
  file { $::quantum::params::quantum_dhcp_agent_ini: }

  if $quantum_settings {
    multini($::quantum::params::quantum_conf, $quantum_settings)
  }

  if $keystone_enabled {
    multini($::quantum::params::quantum_conf, { 'DEFAULT' => { 'auth_strategy' => 'keystone' } })
    $keystone_settings = {
      'filter:authtoken' => {
        'auth_host'         => $keystone_auth_host,
        'auth_port'         => $keystone_auth_port,
        'auth_protocol'     => $keystone_auth_protocol,
        'admin_user'        => $keystone_user,
        'admin_password'    => $keystone_password,
        'admin_tenant_name' => $keystone_tenant
      }
    }
 
    multini($::quantum::params::quantum_paste_api_ini, $keystone_settings)
 
    # Only enable DHCP if Keystone is enabled
    if $dhcp_enabled {
      $auth_url = "${keystone_auth_protocol}://${keystone_auth_host}:${keystone_auth_port}/v2.0"
      $dhcp_keystone_settings = {
        'DEFAULT' => {
          'auth_url'          => $auth_url,
          'admin_tenant_name' => $keystone_tenant,
          'admin_user'        => $keystone_user,
          'admin_password'    => $keystone_password,
        }
      }
      if $quantum_dhcp_settings {
        multini($::quantum::params::quantum_dhcp_agent_ini, $quantum_dhcp_settings)
      }
      multini($::quantum::params::quantum_dhcp_agent_ini, $dhcp_keystone_settings)
    }
  }

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { $::quantum::params::service_name:
    enable  => $enabled,
    ensure  => $ensure,
    require => Package[$::quantum::params::package_name],
    subscribe => File[$::quantum::params::quantum_conf],
  }

  # This is a hack. Most likely a bug in the Ubuntu package
  #file { '/usr/lib/python2.7/dist-packages/bin/nova-dhcpbridge':
  #  type   => link,
  #  target => '/usr/bin/nova-dhcpbridge',
  #}

}
