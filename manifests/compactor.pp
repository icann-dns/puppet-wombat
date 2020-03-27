# @summary module to install wombat compactor
#
class wombat::compactor (
  Stdlib::Absolutepath                $data,
  Integer                             $disk_usage_watermark,
  Integer                             $disk_file_aging,
  Boolean                             $promiscuous_mode,
  Integer[60,3600]                    $rotation_period,
  Boolean                             $raw_pcap,
  Boolean                             $ignored_pcap,
  Array[Wombat::Capture_data]         $capture_data,
  Array[Stdlib::IP::Address]          $ip_addresses,
  Optional[Wombat::Listen_interfaces] $listen_interfaces,
  ENUM['gzip','xz']                   $compression,
  Integer[0,9]                        $compression_level,
  ENUM['gzip','xz']                   $pcap_compression,
  Integer[0,9]                        $pcap_compression_level,
  Array[Integer[0,4096]]              $vlan_id,
  String                              $package,
  Stdlib::Absolutepath                $conf_dir,
  Stdlib::Absolutepath                $conf_file,
  Stdlib::Absolutepath                $tools,
  String                              $service,
  Boolean                             $enable,
  Boolean                             $enable_zabbix,
) {

  $_listen_interfaces = $listen_interfaces ? {
    undef   => $facts['networking']['interfaces'].keys(),
    default => $listen_interfaces,
  }
  $ensure = $enable ? {
    true    => 'present',
    default => 'absent',
  }

  $_directories = [ $data , $conf_dir ]
  ensure_packages($package, {'ensure' => 'latest'})
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', mode => '0755' }
  )

  file {$conf_file:
    ensure  => present,
    require => Package[$package],
    content => template('wombat/etc/dns-stats-compactor/compactor.conf.erb'),
  }
  file{"/etc/default/${service}":
    ensure  => present,
    require => Package[$package],
    content => template('wombat/etc/default/dns-stats-compactor.erb'),
  }
  file{"${tools}/rotate":
    ensure  => present,
    mode    => '0755',
    content => template('wombat/bin/compactor_rotate.erb'),
  }
  file {'/lib/systemd/system/dns-stats-compactor.service':
    mode    => '0644',
    owner   => root,
    group   => root,
    require => Package[$package],
    content => template('wombat/lib/systemd/system/dns-stats-compactor.service.erb'),
  }~> exec { 'compactor-systemd-reload':
      command     => 'systemctl daemon-reload',
      path        => [ '/bin', ],
      refreshonly => true,
      }

  service {$service:
    ensure    => $enable,
    enable    => $enable,
    require   => File[$conf_file,"/etc/default/${service}"],
    subscribe => File[$conf_file,"/etc/default/${service}"],
  }
  cron {'compactor_rotate':
    ensure  => $ensure,
    command => "/usr/bin/flock -n /var/lock/rotate.lock ${tools}/rotate",
    user    => 'root',
    require => File["${tools}/rotate"];
  }
}
