# @summary install wombat tools and configuration for wombat datastore processing
#
# @param packages packages to install
# @param archive_dir location of archive directory
# @param standby if this system is a standby or primary DB
# @param queue_user gearman queue service user
# @param data_user system user to run as
# @param enable_rotate enables the file rotation and expiration of files
# @param cbor_expiration specifies a data aging in days for files keep
# @param pcap_expiration specifies a data aging in days for files keep
# @param services array of services to process
#
class wombat::datastore (
  Array[String[1]]                $packages,
  Stdlib::Unixpath                $archive_dir,
  Boolean                         $standby,
  String[1]                       $queue_user,
  String                          $data_user,
  Boolean                         $enable_rotate,
  Integer[1,365]                  $cbor_expiration,
  Integer[1,365]                  $pcap_expiration,
  Array[String[1]]                $services,
) {
  include wombat::config
  include postgresql::server

  $data = $wombat::config::data_path
  $_service_directories = $services.map |String $service| {
    ["${data}/${service}",]
  }.flatten
  $_directories = [$data,] + $_service_directories
  ensure_packages($packages)
  ensure_resource(
    'file', $_directories,
    {
      'ensure' => 'directory',
      mode     => '0755',
      owner    => $data_user,
      group    => $data_user
    }
  )

  $ensure = $enable_rotate ? {
    true    => 'present',
    default => 'absent',
  }

  file { $archive_dir:
    ensure => directory,
    owner  => $postgresql::server::user,
    group  => $postgresql::server::group,
  }
  file {'/usr/local/bin/datastore_rotate':
    ensure  => present,
    owner   => root,
    mode    => '0755',
    content => template('wombat/bin/datastore_rotate.erb');
  }
  cron {'datastore_rotate':
    ensure  => $ensure,
    command => '/usr/bin/flock -n /var/lock/rotate.lock /usr/local/bin/datastore_rotate',
    user    => $data_user,
    require => File['/usr/local/bin/datastore_rotate'];
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
    require => File[
        '/etc/systemd/system/gearman-job-server.d/wombat.conf',
        "${wombat::config::conf_dir}/wombat.cfg",
    ],
  }
  if $standby {
    include wombat::datastore::standby
  } else {
    include wombat::datastore::primary
  }
}
