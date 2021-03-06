class quantum::plugins::openvswitch::compute (
  $db_pass,
  $private_interface,
  $db_host = 'localhost',
  $db_name = 'ovs_quantum',
  $db_user = 'quantum',
  $bridge  = 'br-int',
) {

  nova_config {
    'linuxnet_interface_driver': value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
    'linuxnet_ovs_integration_bridge': value => 'br-int';
    'libvirt_ovs_bridge': value => $bridge;
    'libvirt_vif_type': value => 'ethernet';
    'libvirt_vif_driver': value => 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver';
  }

  exec { "ovs-vsctl add-br ${bridge}":
    command => "ovs-vsctl add-br ${bridge}",
    unless  => "ovs-vsctl list-br | grep ${bridge}",
    path    => ['/bin', '/usr/bin'],
  }

  exec { "ovs-vsctl add-port ${private_interface}":
    command => "ovs-vsctl add-port ${private_interface}",
    unless  => "ovs-vsctl list-ports ${bridge} | grep ${private_interface}",
    path    => ['/bin', '/usr/bin'],
  }

  $sql_connection = "mysql://${db_user}:${db_pass}@${db_host}:3306/${db_name}"

  file { '/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini':
    ensure  => present,
    owner   => 'quantum',
    group   => 'quantum',
    mode    => '0644',
    content => template('quantum/ovs_quantum_plugin.ini.erb'),
  }

  file { '/etc/sudoers.d/quantum_sudoers':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
    source => 'puppet:///modules/quantum/quantum_sudoers',
  }

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

  file { '/etc/libvirt/qemu.conf':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/quantum/qemu.conf',
  }

}
