# @summary module to install wombat compactor
#
class wombat::compactor (
  Stdlib::Absolutepath                $data,
  Integer                             $disk_usage_watermark,
  Integer                             $disk_file_aging,
  Boolean                             $promiscuous_mode,
  Integer[60,3600]                    $rotation_period,
  Optional[String]                    $max_output_size,
  Boolean                             $raw_pcap,
  Boolean                             $ignored_pcap,
  Array[Wombat::Capture_data]         $capture_data,
  Array[Stdlib::IP::Address]          $ip_addresses,
  Optional[Wombat::Listen_interfaces] $listen_interfaces,
  Optional[String]                    $filter,
  ENUM['gzip','xz']                   $compression,
  Integer[0,9]                        $compression_level,
  ENUM['gzip','xz']                   $pcap_compression,
  Integer[0,9]                        $pcap_compression_level,
  Array[Integer[0,4096]]              $vlan_id,
  Optional[Stdlib::Absolutepath]      $dnstap_socket,
  String                              $dnstap_socket_owner,
  String                              $dnstap_socket_group,
  ENUM['all','user','group']          $dnstap_socket_write,
  String                              $package,
  Stdlib::Absolutepath                $conf_dir,
  Stdlib::Absolutepath                $tools,
  String                              $service,
  Boolean                             $enable,
) {

  $_listen_interfaces = $listen_interfaces ? {
    undef   => $facts['networking']['interfaces'].keys(),
    default => $listen_interfaces,
  }
  $ensure = $enable ? {
    true    => 'present',
    default => 'absent',
  }

  # Calculate resources for compactor
  if $facts['processorcount'] < 9 {
     $cpuset = [0]
  } elsif $facts['processorcount'] < 17 {
     $cpuset = [0,1]
  } else {
     $cpuset = [0,1,2,3]
  }
  $memory_gbytes = round(($facts['memorysize_mb'] / 1024))
  if $memory_gbytes < 17 {
     $memory_max = 2
  } else {
     $memory_max = round($memory_gbytes / 8 )
  }
  $memory_high = $memory_max -1

  $_directories = [ $data , $conf_dir ]
  ensure_packages($package, {'ensure' => 'latest'})
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', mode => '0755' }
  )

  file { "${conf_dir}/compactor.conf":
    ensure  => present,
    require => Package[$package],
    content => template('wombat/etc/dns-stats-compactor/compactor.conf.erb'),
  }
#  file { "${conf_dir}/excluded_fields.conf":
#    ensure  => present,
#    require => Package[$package],
#    content => template('wombat/etc/dns-stats-compactor/excluded_fields.conf.erb'),
#  }
  file { "${conf_dir}/default_values.conf":
    ensure  => present,
    require => Package[$package],
    source  => 'puppet:///modules/wombat/etc/dns-stats-compactor/default_values.conf',
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
    require   => File[ "${conf_dir}/compactor.conf","/etc/default/${service}"],
    subscribe => File[ "${conf_dir}/compactor.conf","/etc/default/${service}"],
  }
  cron {'compactor_rotate':
    ensure  => $ensure,
    command => "/usr/bin/flock -n /var/lock/rotate.lock ${tools}/rotate",
    user    => 'root',
    require => File["${tools}/rotate"];
  }
}
