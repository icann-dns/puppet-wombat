# @summary class to ensure postgress is configuered as the primary database
#
# @param ipv4_address ipv4 address to allow for replication
# @param ipv6_address ipv4 address to allow for replication
# @param roles a hash of roles to be used with postgresql::server::role
# @param data_user system user
class wombat::datastore::primary (
  Stdlib::IP::Address::V4    $ipv4_address,
  Stdlib::IP::Address::V6    $ipv6_address,
  Hash[String, Hash]         $roles,
  Wombat::Synchronous_commit $synchronous_commit,
  String[1]                  $data_user,
) {
  assert_private()
  include wombat::datastore
  include wombat::rssacd

  $archive_dir = $wombat::datastore::archive_dir

  postgresql::server::db { 'wombat':
    user     => 'wombat',
    password => 'NOT USED AS USER CREATED WITH ROLES',
    before   => Postgresql::Server::Config_entry['synchronous_standby_names'],
  }
  postgresql::server::pg_hba_rule { 'replication_v4':
    address     => $ipv4_address,
    auth_method => 'md5',
    database    => 'replication',
    order       => 5,
    type        => 'host',
    user        => 'wombat_replication',
  }
  postgresql::server::pg_hba_rule { 'replication_v6':
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
  postgresql::server::config_entry { 'wal_keep_segments':
    ensure => present,
    value  => '10',
  }
  postgresql::server::config_entry { 'synchronous_commit':
    ensure => present,
    value  => $synchronous_commit,
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
  $roles.each |$rolename, $role| {
    postgresql::server::role { $rolename:
      * => $role,
    }
  }
  $schema = '/usr/share/wombat-server/sql/postgres/ddl'
  exec {"/usr/bin/wombat-postgres-update ${schema}":
    unless  => "/usr/bin/wombat-postgres-update -r ${schema}",
    require => Postgresql::Server::Db['wombat'],
  }
  file { '/etc/wombat/nodes.csv':
    audit  => content,
    notify => Exec['wombat-nodes-update'],
  }
  exec { 'wombat-nodes-update':
    command     => '/usr/bin/wombat-nodes-update /etc/wombat/nodes.csv',
    refreshonly => true,
    user        => wombat,
  }
  cron {'wombat-prune':
    ensure  => present,
    command => '/usr/bin/wombat-prune --threshold 75 --force',
    user    => $data_user,
    minute  => '0',
    hour    => '1',
    weekday => '0',
  }
  cron {'wombat-tld-update':
    ensure  => present,
    command => '/usr/bin/wombat-tld-update',
    user    => $data_user,
    minute  => '0',
    hour    => '2',
  }
}
