# @summary module to install wombat compactor
# @param data path where data is stored
# @param disk_usage_watermark percentage of disk usage to trigger compaction
# @param disk_file_aging number of days to keep files
# @param promiscuous_mode enable promiscuous mode
# @param rotation_period period to rotate files
# @param max_output_size maximum output size
# @param raw_pcap enable raw pcap
# @param ignored_pcap enable ignored pcap
# @param capture_data array of capture data
# @param ip_addresses array of ip addresses
# @param listen_interfaces array of listen interfaces
# @param filter filter to use
# @param compression compression type
# @param compression_level compression level
# @param pcap_compression pcap compression type
# @param pcap_compression_level pcap compression level
# @param vlan_id array of vlan ids
# @param dnstap_socket dnstap socket
# @param dnstap_socket_owner dnstap socket owner
# @param dnstap_socket_group dnstap socket group
# @param dnstap_socket_write dnstap socket write
# @param package package to install
# @param conf_dir configuration directory
# @param tools tools directory
# @param service service name
# @param enable enable the service
# @param log_network_stats_period period to log network stats
# @param log_file_handling enable log file handling
# @param sampling_enable enable sampling
# @param sampling_threshold sampling threshold
# @param sampling_rate sampling rate
# @param sampling_time sampling time
# @param query_timeout query timeout
# @param skew_timeout skew timeout
# @param max_compression_threads maximum compression threads
# @param compactor_options compactor options
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
  Integer[0,3600]                     $log_network_stats_period,
  Boolean                             $log_file_handling,
  Boolean                             $sampling_enable,
  Integer[1,100]                      $sampling_threshold,
  Integer[2,1000]                     $sampling_rate,
  Integer[10,3600]                    $sampling_time,
  Integer[1,5]                        $query_timeout,
  Integer[0]                          $skew_timeout,
  Integer[1,10]                       $max_compression_threads,
  Optional[String]                    $compactor_options,
) {
  $_listen_interfaces = $listen_interfaces.lest || { $facts['networking']['interfaces'].keys() }
  $ensure = $enable.bool2str('present','absent')

  # Calculate resources for compactor
  $cpuset = $facts['processors']['count'] ? {
    Integer[0,8]  => [0],
    Integer[9,16] => [0,1],
    default       => [0,1,2,3],
  }
  $memory_gbytes = round(($facts['memory']['system']['total_bytes'] / 1024 / 1024 / 1024))
  $memory_max = $memory_gbytes < 17 ? {
    true => 2,
    false => round($memory_gbytes / 8),
  }
  $memory_high = $memory_max -1

  $_directories = [$data , $conf_dir]
  ensure_packages($package, { 'ensure' => 'latest' })
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', mode => '0755' }
  )

  file { "${conf_dir}/compactor.conf":
    ensure  => file,
    content => template('wombat/etc/dns-stats-compactor/compactor.conf.erb'),
    require => Package[$package],
  }
  file { "${conf_dir}/default_values.conf":
    ensure  => file,
    source  => 'puppet:///modules/wombat/etc/dns-stats-compactor/default_values.conf',
    require => Package[$package],
  }
  file { "/etc/default/${service}":
    ensure  => file,
    content => template('wombat/etc/default/dns-stats-compactor.erb'),
    require => Package[$package],
  }
  file { "${tools}/rotate":
    ensure  => file,
    mode    => '0755',
    content => template('wombat/bin/compactor_rotate.erb'),
  }
  file { '/lib/systemd/system/dns-stats-compactor.service':
    mode    => '0644',
    owner   => root,
    group   => root,
    require => Package[$package],
    content => template('wombat/lib/systemd/system/dns-stats-compactor.service.erb'),
    notify  => Exec['compactor-systemd-reload'],
  }
  exec { 'compactor-systemd-reload':
    command     => 'systemctl daemon-reload',
    path        => ['/bin',],
    refreshonly => true,
  }

  service { $service:
    ensure    => $enable,
    enable    => $enable,
    require   => File["${conf_dir}/compactor.conf","/etc/default/${service}"],
    subscribe => File["${conf_dir}/compactor.conf","/etc/default/${service}"],
  }
  cron { 'compactor_rotate':
    ensure  => $ensure,
    command => "/usr/bin/flock -n /var/lock/rotate.lock ${tools}/rotate",
    user    => 'root',
    require => File["${tools}/rotate"];
  }
}
