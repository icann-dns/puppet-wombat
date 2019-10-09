# @summary installs the required configuration files for grafana
#
# @param wombat_cluser_host setup the host of the clickhouse cluster to query 
# @param wombat_cluser_port setup the TCP port for the clickhouse cluster to query
#
class wombat::grafana_config (
  Stdlib::Host                    $wombat_cluser_host,
  Integer[1]                      $wombat_cluser_port
) {
  file {'/etc/grafana/provisioning/datasources/wombat.yml':
    ensure  => present,
    owner   => root,
    group   => grafana,
    mode    => '0640',
    content => template('wombat/etc/grafana/provisioning/datasources/wombat.yml.erb'),
  }
}
