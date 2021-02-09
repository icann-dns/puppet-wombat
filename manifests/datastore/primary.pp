# @summary class to ensure postgress is configured as the primary database
#
# @param ipv4_address ipv4 address to allow for replication
# @param ipv6_address ipv6 address to allow for replication
# @param replicate a boolean setup postgresql replication
# @param roles a hash of roles to be used with postgresql::server::role
# @param schema_dir path to the schema DDLs
# @param schema_update a boolean allow puppet to perform a schema update, if available
# @param synchronous_commit a boolean to enable synchronous commits
# @param min_partitions integer ensure a minimum number of raw data partitions
# @param s_max_age integer maximum 1s aggregated data partition age in days
# @param m_max_age integer maximum 5m aggregated data partition age in days
# @param threshold integer set disk usage percentage threshold
# @param nodes_update a boolean allow puppet to perform a nodes update, if available
#
class wombat::datastore::primary (
  Stdlib::IP::Address::V4    $ipv4_address,
  Stdlib::IP::Address::V6    $ipv6_address,
  Boolean                    $replicate,
  Hash[String, Hash]         $roles,
  Stdlib::Unixpath           $schema_dir,
  Boolean                    $schema_update,
  Wombat::Synchronous_commit $synchronous_commit,
  Integer                    $min_partitions,
  Integer                    $s_max_age,
  Integer                    $m_max_age,
  Integer                    $threshold,
  Boolean                    $nodes_update,
) {
  assert_private()
  include wombat::datastore
  include wombat::rssacd

  $archive_dir = $wombat::datastore::archive_dir

  $ensure_replicate = $replicate ? {
    true    => 'present',
    default => 'absent',
  }

  postgresql::server::db { 'wombat':
    user     => 'wombat',
    password => 'NOT USED AS USER CREATED WITH ROLES',
    before   => Postgresql::Server::Config_entry['synchronous_standby_names'],
  }
  postgresql::server::pg_hba_rule { 'replication_v4':
    address     => $ipv4_address,
    auth_method => 'md5',
    database    => 'replication',
    order       => 301,
    type        => 'host',
    user        => 'wombat_replication',
  }
  postgresql::server::pg_hba_rule { 'replication_v6':
    address     => $ipv6_address,
    auth_method => 'md5',
    database    => 'replication',
    order       => 302,
    type        => 'host',
    user        => 'wombat_replication',
  }
  postgresql::server::config_entry { 'archive_command':
    ensure => $ensure_replicate,
    value  => "test ! -f ${archive_dir}/%f && cp %p ${archive_dir}/%f",
  }
  postgresql::server::config_entry { 'archive_mode':
    ensure => $ensure_replicate,
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
    ensure => $ensure_replicate,
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
  if $schema_update {
    exec {"/usr/bin/wombat-postgres-update ${schema_dir}":
      unless  => "/usr/bin/wombat-postgres-update -r ${schema_dir}",
      require => Postgresql::Server::Db['wombat'],
    }
  }
  if $nodes_update {
    file { '/etc/wombat/nodes.csv':
      source => 'http://files.dns.icann.org/nodes.csv',
      notify => Exec['wombat-nodes-update'],
    }
    exec { 'wombat-nodes-update':
      command     => '/usr/bin/wombat-nodes-update /etc/wombat/nodes.csv',
      refreshonly => true,
      user        => $wombat::config::user,
    }
  }
  cron {'wombat-prune':
    ensure  => present,
    command => "/usr/bin/wombat-prune -t ${threshold} -m ${min_partitions} -1 ${s_max_age} -5 ${m_max_age} --force",
    user    => $wombat::config::user,
    minute  => '0',
    hour    => '1',
  }
  cron {'wombat-tld-update':
    ensure  => present,
    command => '/usr/bin/wombat-tld-update',
    user    => $wombat::config::user,
    minute  => '0',
    hour    => '2',
  }
  cron {'wombat-geo-update':
    ensure  => present,
    command => '/usr/bin/wombat-geo-update',
    user    => $wombat::config::user,
    minute  => '0',
    hour    => '2',
    weekday => '7',
  }
}
