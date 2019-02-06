# @summary install wombat tools and configueration for wombat datastore processing
#
# @param packages packages to install
# @param conf_dir configuration file directory
# @param clickhouse_template clickhouse tsv template
# @param data_path path where data is stored
# @param incoming_dir_pattern bash expansion fo incoming files
# @param reload_dir_pattern bash expansion fo cbor files
# @param pcap_dir_pattern bash expansion fo pcap files
# @param db_name database name
# @param db_user database user
# @param db_pass database password
# @param db_host database host
# @param clickhouse_servers list of clickhouse servers
# @param archive_dir location of archive directory
# @param loggers Hash of logger configueration
# @param standby if this system is a standby or primary DB
# @param anonymisation_passphrase if present use this password for anonimisation
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
  String[1]                       $db_pass,
  Stdlib::Host                    $db_host,
  Array[Stdlib::Host]             $clickhouse_servers,
  String[1]                       $clickhouse_user,
  String[1]                       $clickhouse_pass,
  Stdlib::Unixpath                $archive_dir,
  Hash[String[1], Wombat::Logger] $loggers,
  Boolean                         $standby,
  String[1]                       $queue_user,
  Optional[String[1]]             $anonymisation_passphrase,
) {
  ensure_packages($packages)
  include postgresql::server
  file {"${conf_dir}/tsv-clickhouse.tpl":
    ensure => file,
    source => $clickhouse_template,
  }
  file { $archive_dir:
    ensure => directory,
    owner  => $postgresql::server::user,
    group  => $postgresql::server::group,
  }
  file {$conf_dir:
    ensure => directory,
  }
  file {"${conf_dir}/wombat.cfg":
    ensure  => file,
    content => template('wombat/etc/wombat/wombat.cfg.erb'),
    notify  => Service['gearman-job-server'],
  }
  cron {'wombat queue manager':
    command => '/usr/bin/wombat-import -s incoming',
    user    => $queue_user,
    minute  => '*/5',
  }
  file {'/etc/systemd/system/gearman-job-server.d':
    ensure => directory,
  }
  file {'/etc/systemd/system/gearman-job-server.d/wombat.conf':
    ensure  => file,
    content => "[Service]\nExecStartPost=/usr/bin/wombat-import -s pending",
    require => Package[$packages],
  }
  service {'gearman-job-server':
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/gearman-job-server.d/wombat.conf'],
  }
  if $standby {
    include wombat::datastore::standby
  } else {
    include wombat::datastore::primary
  }

}
