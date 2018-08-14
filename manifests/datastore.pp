# @summary install wombat tools and configueration for wombat datastore processing
#
# @param packages packages to install
# @param conf_dir configuration file directory
# @param clickhouse_template clickhouse tsv template
# @param data_path path where data is stored
# @param incoming_dir_pattern bash expansion fo incoming files
# @param reload_dir_patter bash expansion fo cbor files
# @param pcap_dir_patter bash expansion fo pcap files
# @param db_name database name
# @param db_user database user
# @param db_host database host
# @param clickhouse_servers list of clickhouse servers
# @param loggers Hash of logger configueration
#
class wombat::datastore (
  Array[String[1]]                $packages,
  Stdlib::Unixpath                $conf_dir,
  Stdlib::Filesource              $clickhouse_template,
  Stdlib::Filesource              $data_path,
  String[1]                       $incoming_dir_pattern,
  String[1]                       $reload_dir_pattern,
  String[1]                       $pcap_dir_pattern,
  String[1]                       $db_name,
  String[1]                       $db_user,
  Stdlib::Host                    $db_host,
  Array[Stdlib::Host]             $clickhouse_servers,
  Hash[String[1], Wombat::Logger] $loggers,
) {
  ensure_packages($packages)
  file {"${conf_dir}/tsv-clickhouse.tpl":
    ensure => file,
    source => $clickhouse_template,
  }
  file {$conf_dir:
    ensure => directory,
  }
  file {"${conf_dir}/wombat.cfg":
    ensure  => file,
    content => template('wombat/etc/wombat/wombat.cfg.erb'),
  }
}
