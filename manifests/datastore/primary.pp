# @summary class to ensure postgress is configured as the primary database
#
# @param ipv4_address ipv4 address to allow for replication
# @param ipv6_address ipv6 address to allow for replication
# @param replicate a boolean setup postgresql replication
# @param roles a hash of roles to be used with postgresql::server::role
# @param schema_dir path to the schema DDLs
# @param schema_update a boolean allow puppet to perform a schema update, if available
# @param synchronous_commit a boolean to enable synchronous commits
# @param r_min_data_age integer number of days of raw data to be retained
# @param s_min_data_age integer number of days of aggregation data to be retained for 1s aggregation
# @param m_min_data_age integer number of days of aggregation data to be retained for 5m aggregation
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
  Integer                    $r_min_data_age,
  Integer                    $s_min_data_age,
  Integer                    $m_min_data_age,
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
  file { '/etc/wombat/regions.csv':
    source => 'puppet:///modules/artifacts/etc/wombat/regions.csv',
  }

  cron {'wombat-prune-agg-5m':
    ensure  => present,
    command => "/usr/bin/wombat-prune -t ${threshold} -d 5min -a ${m_min_data_age} -s --force",
    user    => $wombat::config::user,
    minute  => '10',
    hour    => '1',
  }
  cron {'wombat-prune-agg-1s':
    ensure  => present,
    command => "/usr/bin/wombat-prune -t ${threshold} -d 1s -a ${s_min_data_age} -s --force",
    user    => $wombat::config::user,
    minute  => '5',
    hour    => '1',
  }
  cron {'wombat-prune':
    ensure  => present,
    command => "/usr/bin/wombat-prune -t ${threshold} -d raw -a ${r_min_data_age} -i -s --force",
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
  cron {'wombat-rssac-instance-update':
    ensure  => present,
    command => '/usr/bin/wombat-rssac-instance-update',
    user    => $wombat::config::user,
    minute  => '0',
    hour    => '*/12',
  }
  cron {'wombat-nodes-update_audit':
    ensure  => present,
    command => '/usr/bin/wombat-nodes-update -a --auditfile=/tmp/wombat_audit /etc/wombat/nodes.csv',
    user    => $wombat::config::user,
    minute  => '30',
    hour    => '0',
  }
}
