# @summary module to manage and configure wombat
#
# @param packages packages to install
# @param db_driver database db driver
# @param db_host database host
# @param db_name database name
# @param db_username database username
# @param db_password database password
# @param db_port database port
# @param odbc_file location of odbc file
# @param odbcinst_file location of odbcinst file
# @param odbc_logdir location of odbc logdirectory
# @param owner file system user
#
class wombat::cluster (
  Array[String[1]]   $packages,
  String[1]          $db_driver,
  Stdlib::Host       $db_host,
  String[1]          $db_name,
  String[1]          $db_username,
  String[1]          $db_password,
  Stdlib::Port       $db_port,
  Stdlib::Unixpath   $odbc_file,
  Stdlib::Unixpath   $odbcinst_file,
  Stdlib::Unixpath   $odbc_logdir,
  String[1]          $owner,
) {
  ensure_packages($packages)
  include wombat::config
  file {$odbc_file:
    ensure  => file,
    owner   => $owner,
    mode    => '0600',
    content => template('wombat/etc/odbc.ini.erb'),
  }
  file {$odbc_logdir:
    ensure => directory,
    owner  => $owner,
  }
  file { '/usr/local/bin/zbx_clickhouse_monitor.sh':
    ensure => file,
    source => 'puppet:///modules/wombat/usr/local/bin/zbx_clickhouse_monitor.sh',
    mode   => '0755';
  }
  ini_setting {'set log file':
    ensure            => present,
    path              => $odbcinst_file,
    section           => 'PostgreSQL Unicode',
    setting           => 'Logdir',
    key_val_separator => '=',
    value             => $odbc_logdir,
  }
  $schema = '/usr/share/wombat-server/sql/clickhouse/ddl'
  exec {"/usr/bin/wombat-clickhouse-update ${schema}":
    unless => "/usr/bin/wombat-clickhouse-update -r ${schema}",
  }
}
