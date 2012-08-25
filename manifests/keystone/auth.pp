class quantum::keystone::auth (
  $password,
  $auth_name          = 'quantum',
  $email              = 'quantum@localhost',
  $tenant             = 'services',
  $configure_endpoint = true,
  $service_type       = 'network',
  $public_address     = '127.0.0.1',
  $admin_address      = '127.0.0.1',
  $internal_address   = '127.0.0.1',
  $port               = '9696',
  $region             = 'RegionOne'
) {

  Keystone_user_role["${auth_name}@services"] ~> Service <| name == 'quantum-registry' |>
  Keystone_user_role["${auth_name}@services"] ~> Service <| name == 'quantum-api' |>

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }
  keystone_user_role { "${auth_name}@services":
    ensure  => present,
    roles   => 'admin',
  }
  keystone_service { $auth_name:
    ensure      => present,
    type        => $service_type,
    description => "Quantum Networking Service",
  }

  if $configure_endpoint {
    keystone_endpoint { $auth_name:
      ensure       => present,
      region       => $region,
      public_url   => "http://${public_address}:${port}/v2.0",
      admin_url    => "http://${admin_address}:${port}/v2.0",
      internal_url => "http://${internal_address}:${port}/v2.0",
    }
  }
}
