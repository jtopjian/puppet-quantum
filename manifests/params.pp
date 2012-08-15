class quantum::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'quantum-server'
      $service_name = 'quantum-server'
    }
  }
}
