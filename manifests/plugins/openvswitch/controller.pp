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

  #$packages = ['quantum-plugin-openvswitch', 'openvswitch-datapath-source']
  #package { $packages:
  #  ensure => latest,
  #}

  $plugin = 'quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2'
  quantum::config {
    "/etc/quantum/quantum.conf DEFAULT core_plugin ${plugin}":
      require => File['/etc/quantum/quantum.conf'],
  }

}
