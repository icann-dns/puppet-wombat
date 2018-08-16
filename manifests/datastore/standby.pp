# @summary class to ensure postgress is configuered as the standby database
#
class wombat::datastore::standby (
  Stdlib::IP::Address $db_host,
  String              $db_username,
  String              $db_password,
) {
  assert_private()
  include wombat::datastore

  $archive_dir = $wombat::datastore::archive_dir
  postgresql::server::pg_hba_rule { 'replication_v4': ensure => absent }
  postgresql::server::pg_hba_rule { 'replication_v4': ensure => absent }
  postgresql::server::config_entry { 'archive_command': ensure => absent }
  postgresql::server::config_entry { 'archive_mode': ensure => absent }
  postgresql::server::config_entry { 'max_wal_senders': ensure => absent }
  postgresql::server::config_entry { 'synchronous_standby_names':
    ensure => absent,
  }
  postgresql::server::config_entry { 'wal_level': ensure => absent }
  postgresql::server::config_entry { 'hot_standby':
    ensure => present,
    valude => 'on',
  }
  file {'/etc/postgresql/10/main/recovery.conf':
    ensure  => file,
    content => template('wombat/etc/postgresql/10/main/recovery.conf.erb'),
    notify  => Service[$postgresql::server::service_name],
  }
}
