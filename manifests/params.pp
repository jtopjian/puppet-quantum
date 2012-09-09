class quantum::params {

  $quantum_conf = '/etc/quantum/quantum.conf'
  $quantum_paste_api_ini = '/etc/quantum/api-paste.ini'
  $quantum_dhcp_agent_ini = '/etc/quantum/dhcp_agent.ini'

  $quantum_ovs_plugin_ini = '/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini'

  case $::osfamily {
    'Debian': {
      $package_name       = 'quantum-server'
      $service_name       = 'quantum-server'
      $ovs_package_agent  = 'quantum-plugin-openvswitch-agent'
      $ovs_package_server = 'quantum-plugin-openvswitch'
      $ovs_service_agent  = 'quantum-agent'
      $ovs_service        = 'openvswitch-switch'
      $cliff_name         = 'python-cliff'
    }
  }
}
