class quantum (
  $db_pass,
  $rabbit_pass,
  $keystone_password,
  $enabled           = true,
  $log_verbose       = 'False',
  $log_file          = '/var/log/quantum/quantum.log',
  $log_debug         = 'False',
  $bind_host         = '0.0.0.0',
  $bind_port         = '9696',
  $auth_type         = 'keystone',
  $auth_host         = 'localhost',
  $auth_port         = '35357',
  $auth_protocol     = 'http',
  $auth_version      = '2.0',
  $keystone_user     = 'quantum',
  $dhcp              = false,
  $db_host           = 'localhost',
  $db_name           = 'ovs_quantum',
  $db_user           = 'quantum',
  $plugin            = 'openvswitch',
  $rabbit_host       = '127.0.0.1',
  $rabbit_user       = 'guest'
) inherits quantum::params {

  package { $::quantum::params::package_name:
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

  file { '/etc/quantum/quantum.conf': }
  file { '/etc/quantum/policy.json':
    source => 'puppet:///modules/quantum/policy.json',
  }

  inifile::set {
    ["/etc/quantum/quantum.conf DEFAULT verbose ${log_verbose}",
     "/etc/quantum/quantum.conf DEFAULT debug ${log_debug}",
     "/etc/quantum/quantum.conf DEFAULT log_file ${log_file}",
     "/etc/quantum/quantum.conf DEFAULT bind_host ${bind_host}",
     "/etc/quantum/quantum.conf DEFAULT bind_port ${bind_port}"]:
       require => File['/etc/quantum/quantum.conf'],
  }

  if $enabled {
    $ensure = 'running'
    inifile::set {
     ['/etc/quantum/quantum.conf DEFAULT control_exchange quantum',
      "/etc/quantum/quantum.conf DEFAULT rabbit_host ${rabbit_host}",
      "/etc/quantum/quantum.conf DEFAULT rabbit_user ${rabbit_user}",
      "/etc/quantum/quantum.conf DEFAULT rabbit_password ${rabbit_pass}"]:
       require => File['/etc/quantum/quantum.conf'],
    }
  } else {
    $ensure = 'stopped'
  }
  service { $::quantum::params::service_name:
    enable  => $enabled,
    ensure  => $ensure,
    require => Package[$::quantum::params::package_name],
    subscribe => File['/etc/quantum/quantum.conf'],
  }

  # This is a hack. Most likely a bug in the Ubuntu package
  #file { '/usr/lib/python2.7/dist-packages/bin/nova-dhcpbridge':
  #  type   => link,
  #  target => '/usr/bin/nova-dhcpbridge',
  #}

  if $auth_type == 'keystone' {
    file { '/etc/quantum/api-paste.ini':
      content => template('quantum/api-paste.ini.erb'),
    }
  }

  if $dhcp {
    # Not fully implemented -- missing dhcp agent binary in package
    $db_connection = "mysql://${db_user}:${db_pass}@${db_host}/${db_name}"
    $auth_url = "${auth_protocol}://${auth_host}:${auth_port}/v2.0"
    $d_file = '/etc/quantum/dhcp_agent.ini'
    inifile::set {
      ["${d_file} DEFAULT verbose ${log_verbose}",
       "${d_file} DEFAULT debug ${log_debug}",
       "${d_file} DEFAULT db_connection ${db_connection}",
       "${d_file} DEFAULT auth_url ${auth_url}",
       "${d_file} DEFAULT admin_tenant_name services",
       "${d_file} DEFAULT admin_user ${keystone_user}",
       "${d_file} DEFAULT admin_password ${keystone_password}"]:
    }
    if $plugin == 'openvswitch' {
      inifile::set {
        "${d_file} DEFAULT interface_driver quantum.agent.linux.interface.OVSInterfaceDrive":
      }
    }
  }
}
