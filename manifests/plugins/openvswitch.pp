#
class quantum::plugins::openvswitch (
  $bridge               = 'br-int',
  $private_interface    = 'eth1',
  $openvswitch_settings = false,
  $dhcp_enabled         = true,
  $agent                = false
) {

  include quantum::params

  if $agent {
    $package = $::quantum::params::ovs_package_agent
  } else {
    $package = $::quantum::params::ovs_package_server
  }
  package { 'quantum-plugin-openvswitch':
    name   => $package,
    ensure => latest,
  }

  $plugin = 'quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2'
  $settings = {
    'DEFAULT' => {
      'core_plugin' => $plugin
    }
  }

  multini($::quantum::params::quantum_conf, $settings)

  file { $::quantum::params::quantum_ovs_plugin_ini: }
  if $openvswitch_settings {
    multini($::quantum::params::quantum_ovs_plugin_ini, $openvswitch_settings)
  }

  if $dhcp_enabled {
    $dhcp_settings = {
      'DEFAULT' => {
        'interface_driver' => 'quantum.agent.linux.interface.OVSInterfaceDriver'
      }
    }
    multini($::quantum::params::quantum_dhcp_agent_ini, $dhcp_settings)
  }

  service { $::quantum::params::ovs_service:
    enable     => true,
    ensure     => running,
    hasstatus  => false,
    status     => 'pgrep ovsdb-server',
    notify     => Service[$::quantum::params::service_name],
  }

  Exec {
    path => ['/bin', '/usr/bin'],
  }

  exec { "ovs-vsctl add-br ${bridge}":
    unless  => "ovs-vsctl list-br | grep ${bridge}",
    require => Package[$package],
  }

  exec { "ovs-vsctl br-set-external-id ${bridge} bridge-id br-int":
    unless  => "ovs-vsctl br-get-external-id ${bridge} bridge-id | grep br-int",
    require => Exec["ovs-vsctl add-br ${bridge}"],
  }

  exec { "ovs-vsctl add-port ${bridge} ${private_interface}":
    unless  => "ovs-vsctl list-ports ${bridge} | grep ${private_interface}",
    require => Exec["ovs-vsctl br-set-external-id ${bridge} bridge-id br-int"],
  }

  case $::osfamily {
    'Debian': {
      file { '/etc/init/quantum-agent.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/quantum/quantum-agent.conf',
      }
    
      file { '/etc/init.d/quantum-agent':
        ensure  => link,
        target  => '/lib/init/upstart-job',
        require => File['/etc/init/quantum-agent.conf'],
      }
      $init_file = '/etc/init.d/quantum-agent'
    }
  }

  service { $::quantum::params::ovs_service_agent:
    enable  => true,
    ensure  => running,
    require => [Package[$package], Exec["ovs-vsctl add-port ${bridge} ${private_interface}"], File[$init_file]],
  }

  if $agent {
    file_line { 'qemu.conf cgroup_device_acl':
      path => '/etc/libvirt/qemu.conf',
      line => 'cgroup_device_acl = ["/dev/null", "/dev/full", "/dev/zero", "/dev/random", "/dev/urandom", "/dev/ptmx", "/dev/kvm", "/dev/kqemu", "/dev/rtc", "/dev/hpet", "/dev/net/tun", ]',
    }
  }
}
