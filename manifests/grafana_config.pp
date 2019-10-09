# @summary installs the required configuration files for grafana
#
# @param wombat_cluster_protocol setup the clickhouse cluster to connection http or https 
# @param wombat_cluster_host setup the host of the clickhouse cluster to query 
# @param wombat_cluster_port setup the TCP port for the clickhouse cluster to query
#
class wombat::grafana_config (
  String[1]                       $wombat_cluster_protocol,
  Stdlib::Host                    $wombat_cluster_host,
  Integer[1]                      $wombat_cluster_port
) {
  file {'/etc/grafana/provisioning/datasources':
    ensure  => directory,
    require => Package['grafana'],
  }
  file {'/etc/grafana/provisioning/datasources/wombat.yml':
    ensure  => present,
    owner   => root,
    group   => grafana,
    mode    => '0640',
    content => template('wombat/etc/grafana/provisioning/datasources/wombat.yml.erb'),
    notify  => Service['grafana-server'],
    require => File['/etc/grafana/provisioning/datasources'],
  }
}
