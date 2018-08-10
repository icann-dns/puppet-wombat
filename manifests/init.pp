# @summary module to manage and configure combat
#
# @param packages packages to install
# @param db_host database host
# @param db_name database name
# @param db_username database username
# @param db_password database password
# @param db_port database port
# @param odbc_file location of odbc file
# @param package_src source of wombat-server python wheel
#
class wombat(
  Array[String[1]]   $packages,
  Stdlib::Host       $db_host,
  String[1]          $db_name,
  String[1]          $db_username,
  String[1]          $db_password,
  Stdlib::Port       $db_port,
  Stdlib::Unixpath   $odbc_file,
  Stdlib::Filesource $package_src,
) {
  ensure_packages($packages)
  file {$odbc_file:
    ensure  => file,
    content => template('wombat/etc/odbc.ini.erb'),
  }
  file {'/usr/local/share/wombat_server.whl':
    ensure => file,
    source => $package_src,
  }
  exec {'/usr/bin/pip3 install /usr/local/share/wombat_server.whl':
    refreshonly => true,
    subscribe   => File['/usr/local/share/wombat_server.whl'],
    require     => Package['python3-pip'],
  }
}
