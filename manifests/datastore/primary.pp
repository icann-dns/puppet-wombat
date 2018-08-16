# @summary class to ensure postgress is configuered as the primary database
#
class wombat::datastore::primary (
  Stdlib::IP::Adress::V4 $ipv4_address,
  Stdlib::IP::Adress::V6 $ipv6_address,
) {
  assert_private()
  include wombat::datastore

  $archive_dir = $wombat::datastore::archive_dir
  postgresql::server::pg_hba_rule { 'replication_v4':
    ensure      => present,
    address     => $ipv4_address,
    auth_method => 'md5',
    database    => 'replication',
    order       => 5,
    type        => 'host',
    user        => 'wombat_replication',
  }
  postgresql::server::pg_hba_rule { 'replication_v4':
    ensure      => present,
    address     => $ipv6_address,
    auth_method => 'md5',
    database    => 'replication',
    order       => 6,
    type        => 'host',
    user        => 'wombat_replication',
  }
  postgresql::server::config_entry { 'archive_command':
    ensure => present,
    value  => "test ! -f ${archive_dir}/%f && cp %p ${archive_dir}/%f",
  }
  postgresql::server::config_entry { 'archive_mode':
    ensure => present,
    value  => 'on',
  }
  postgresql::server::config_entry { 'max_wal_senders':
    ensure => present,
    value  => '3',
  }
  postgresql::server::config_entry { 'synchronous_standby_names':
    ensure => present,
    value  => 'FIRST 1 (lax)',
  }
  postgresql::server::config_entry { 'wal_level':
    ensure => present,
    value  => 'replica',
  }
  postgresql::server::config_entry { 'hot_standby': ensure => absent }
  file {'/etc/postgresql/10/main/recovery.conf':
    ensure => absent,
  }
}
