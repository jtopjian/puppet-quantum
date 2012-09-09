#
class quantum::db::mysql (
  $password,
  $dbname = 'quantum',
  $user   = 'quantum',
) {

  mysql::db { $dbname:
    host     => '127.0.0.1',
    user     => $user,
    password => $password,
  }
}
