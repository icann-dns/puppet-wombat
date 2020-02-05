# @summary creates configuration for wombat environment
#
# @param conf_dir configuration file directory
# @param data_path path where data is stored
# @param incoming_dir_pattern bash expansion fo incoming files
# @param reload_dir_pattern bash expansion fo cbor files
# @param pcap_dir_pattern bash expansion fo pcap files
# @param db_name database name
# @param db_user database user
# @param db_pass database password
# @param db_host if present use the specified database host
# @param clickhouse_servers list of clickhouse servers
# @param clickhouse_dbdir directory to store the clickhouse DB
# @param clickhouse_import_server server to use for clickhouse imports
# @param clickhouse_node_shard_default mode to use for node shard selection
# @param clickhouse_user clickhouse user
# @param clickhouse_pass clickhouse password
# @param loggers Hash of logger configueration
# @param pcap_compress boolean enable compression (default=true)
# @param compression_level compression level to use (default=2)
# @param anonymisation_passphrase if present use this password for anonimisation
# @param rssac_url Grafana URL to use when generating the RSSAC report charts
# @param rssac_outdir output base directoy for the RSSAC reports hierarchy
# @param rssac_server server to query for node addresses
# @param rssac_zone zone to listen for NOTIFY messages from
# @param user to be running the wombat services as
# @param data_user owner of the data files
#
class wombat::config (
  Stdlib::Unixpath                $conf_dir,
  Stdlib::Filesource              $data_path,
  String[1]                       $incoming_dir_pattern,
  String[1]                       $reload_dir_pattern,
  String[1]                       $pcap_dir_pattern,
  String[1]                       $db_name,
  String[1]                       $db_user,
  String[1]                       $db_pass,
  Optional[Stdlib::Host]          $db_host,
  Array[Stdlib::Host]             $clickhouse_servers,
  Stdlib::Unixpath                $clickhouse_dbdir,
  Stdlib::Host                    $clickhouse_import_server,
  String[1]                       $clickhouse_node_shard_default,
  String[1]                       $clickhouse_user,
  String[1]                       $clickhouse_pass,
  Hash[String[1], Wombat::Logger] $loggers,
  Boolean                         $pcap_compress,
  Integer[1,9]                    $compression_level,
  Optional[String[1]]             $anonymisation_passphrase,
  Stdlib::HTTPUrl                 $rssac_url,
  Stdlib::Unixpath                $rssac_outdir,
  String[1]                       $rssac_server,
  String[1]                       $rssac_zone,
  String[1]                       $user,
  String[1]                       $data_user,
) {
  file {$conf_dir:
    ensure => directory,
  }
  if $facts['domain'] == 'datastore.dns.icann.org' {
    $_users = $user
    ensure_resource('user', $_users, {'ensure' => 'present', 'groups' => $data_user })
    file {"${conf_dir}/wombat.cfg":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('wombat/etc/wombat/wombat.cfg.erb'),
      notify  => Service['gearman-job-server'],
    }
    file {"${conf_dir}/private.cfg":
      ensure  => file,
      owner   => $user,
      group   => root,
      mode    => '0600',
      content => template('wombat/etc/wombat/private.cfg.erb'),
      notify  => Service['gearman-job-server'],
    }
  } else {
    ensure_resource('user', $user, {'ensure' => 'present'})
    file {"${conf_dir}/wombat.cfg":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('wombat/etc/wombat/wombat.cfg.erb'),
    }
    file {"${conf_dir}/private.cfg":
      ensure  => file,
      owner   => $user,
      group   => root,
      mode    => '0600',
      content => template('wombat/etc/wombat/private.cfg.erb'),
    }
  }
}
