class quantum::plugins::openvswitch::controller (
  $db_pass,
  $db_host = 'localhost',
  $db_name = 'ovs_quantum',
  $db_user = 'quantum'
) {

  mysql::db { $db_name:
    host     => $db_host,
    user     => $db_user,
    password => $db_pass,
  }

  $packages = ['quantum-plugin-openvswitch', 'openvswitch-datapath-source']

  package { $packages:
    ensure => latest,
  }

  $plugin = 'quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPlugin'
  file { '/etc/quantum/plugin.ini':
    ensure  => present,
    owner   => 'quantum',
    group   => 'quantum',
    mode    => '0644',
    content => template('quantum/plugins.ini.erb'),
  }

}
