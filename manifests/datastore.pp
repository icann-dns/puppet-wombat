# @summary install wombat tools and configuration for wombat datastore processing
#
# @param packages packages to install
# @param archive_dir location of archive directory
# @param standby if this system is a standby or primary DB
# @param enable_rotate enables the file rotation and expiration of files
# @param enable_mirror Enable to wombat-import-mirror
# @param cbor_expiration specifies a data aging in days for files keep
# @param pcap_expiration specifies a data aging in days for files keep
# @param cbor_process_cron specifies the frequency for the cfor file detection and file queuing
# @param services array of services to process
# @param mirror_filters A list of filters for the import mirror
# @param wombat_filter_file (optional) source file for wombat filter
#
class wombat::datastore (
  Array[String[1]]    $packages,
  Stdlib::Unixpath    $archive_dir,
  Boolean             $standby,
  Boolean             $enable_rotate,
  Boolean             $enable_mirror      = true,
  Integer[1,400]      $cbor_expiration,
  Integer[1,400]      $pcap_expiration,
  Integer[1,15]       $cbor_process_cron,
  Array[String[1]]    $services,
  Array[String[1]]    $mirror_filters     = [],
  Optional[String[1]] $wombat_filter_file = undef,
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
      mode     => '0775',
      owner    => $wombat::config::data_user,
      group    => $wombat::config::data_user,
    }
  )
  if $wombat_filter_file {
    file { "${wombat::config::data_path}/wombat.filter":
      ensure  => file,
      owner   => $wombat::config::data_user,
      group   => $wombat::config::data_user,
      source  => $wombat_filter_file,
      require => File[$wombat::config::data_path],
    }
  }

  $ensure = $enable_rotate ? {
    true    => 'present',
    default => 'absent',
  }

  file { $archive_dir:
    ensure => directory,
    owner  => $postgresql::server::user,
    group  => $postgresql::server::group,
  }
  file { '/usr/local/bin/datastore_rotate':
    ensure  => file,
    owner   => root,
    mode    => '0755',
    content => template('wombat/bin/datastore_rotate.erb');
  }
  cron { 'datastore_rotate':
    ensure  => $ensure,
    command => '/usr/bin/flock -n /var/lock/rotate.lock /usr/local/bin/datastore_rotate',
    user    => root,
    minute  => '*/5',
    require => File['/usr/local/bin/datastore_rotate'];
  }
  cron { 'wombat queue manager':
    command     => '/usr/bin/wombat-import -s incoming -q -l 4',
    user        => $wombat::config::user,
    minute      => "*/${cbor_process_cron}",
    environment => 'MAILTO=""',
  }
  file { '/etc/systemd/system/gearman-job-server.d':
    ensure => directory,
  }
  file { '/etc/systemd/system/gearman-job-server.d/wombat.conf':
    ensure  => file,
    content => "[Service]\nExecStartPost=/usr/bin/wombat-import -s pending",
    require => Package[$packages],
  }
  service { 'gearman-job-server':
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
  # only start on the primary
  service { 'wombat-rssac':
    ensure => stdlib::ensure(!$standby, 'service'),
    enable => true,
  }
  # TODO: This should be in the next release
  $unit = ($facts['networking']['hostname'] == 'dev').bool2str('',
    @(UNITTXT)
      [Unit]
      Requires=opt-volume1.mount
      After=opt-volume1.mount
      | UNITTXT
  )
  $override_content = @("CONTENT")
    [Service]
    ExecStart=
    ExecStart=/usr/bin/wombat-import-mirror /opt/volume1/outgoing_staging ${mirror_filters.join(' ')}
    User=
    User=pcapture
    ${unit}
    | CONTENT
  systemd::dropin_file { 'wombat.conf':
    unit    => 'wombat-import-mirror.service',
    content => $override_content,
  }
  service { 'wombat-import-mirror':
    ensure  => stdlib::ensure($enable_mirror, 'service'),
    enable  => $enable_mirror,
    require => Systemd::Dropin_file['wombat.conf'],
  }
}
