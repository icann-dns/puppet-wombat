# @summary install wombat tools and configuration for wombat datastore processing
#
# @param packages packages to install
# @param archive_dir location of archive directory
# @param standby if this system is a standby or primary DB
# @param queue_user gearman queue service user
#
class wombat::datastore (
  Array[String[1]]                $packages,
  Stdlib::Unixpath                $archive_dir,
  Boolean                         $standby,
  String[1]                       $queue_user,
) {
  ensure_packages($packages)
  include wombat::config
  include postgresql::server
  file { $archive_dir:
    ensure => directory,
    owner  => $postgresql::server::user,
    group  => $postgresql::server::group,
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
