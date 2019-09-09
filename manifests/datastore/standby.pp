# @summary class to ensure postgress is configured as the standby database
#
# @param db_host db server to replicate from
# @param db_username db user with replicate permissions
# @param db_password db password with replicate permissions
class wombat::datastore::standby (
  Stdlib::Host               $db_host,
  Array[Stdlib::IP::Address] $db_hostaddr,
  String                     $db_username,
  String                     $db_password,
) {
  assert_private()
  include wombat::datastore

  $archive_dir = $wombat::datastore::archive_dir
  postgresql::server::config_entry { 'archive_command': ensure => absent }
  postgresql::server::config_entry { 'archive_mode': ensure => absent }
  postgresql::server::config_entry { 'max_wal_senders': ensure => absent }
  postgresql::server::config_entry { 'synchronous_standby_names':
    ensure => absent,
  }
  postgresql::server::config_entry { 'wal_level': ensure => absent }
  postgresql::server::config_entry { 'hot_standby':
    ensure => present,
    value  => 'on',
  }
  file {'/var/lib/postgresql/10/main/recovery.conf':
    ensure  => file,
    content => template('wombat/var/lib/postgresql/10/main/recovery.conf.erb'),
    notify  => Class['postgresql::server::service'],
  }
}
