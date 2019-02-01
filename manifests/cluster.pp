# @summary module to manage and configure wombat
#
# @param packages packages to install
# @param db_host database host
# @param db_name database name
# @param db_username database username
# @param db_password database password
# @param db_port database port
# @param odbc_file location of odbc file
#
class wombat::cluster (
  Array[String[1]]   $packages,
  Stdlib::Host       $db_host,
  String[1]          $db_name,
  String[1]          $db_username,
  String[1]          $db_password,
  Stdlib::Port       $db_port,
  Stdlib::Unixpath   $odbc_file,
) {
  ensure_packages($packages)
  file {$odbc_file:
    ensure  => file,
    mode    => '0600',
    content => template('wombat/etc/odbc.ini.erb'),
  }
}
