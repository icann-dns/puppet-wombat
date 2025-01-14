# @summary installs the required configuration files for grafana
#
# @param database clickhouse database to use
# @param uid the uid to use to connect to clickhouse
# @param wombat_cluster_protocol setup the clickhouse cluster to connection http or https
# @param wombat_cluster_host setup the host of the clickhouse cluster to query
# @param wombat_cluster_port setup the TCP port for the clickhouse cluster to query
# @param basic_auth use grafana basicauth default to false
# @param basic_auth_pass username to use for basicauth
#
class wombat::grafana (
  String[1]           $database                = 'wombat',
  String[1]           $uid                     = 'wombat_clickhouse',
  String[1]           $wombat_cluster_protocol = 'http',
  Stdlib::Host        $wombat_cluster_host     = 'localhost',,
  Stdlib::Port        $wombat_cluster_port     = 8123,,
  Boolean             $basic_auth              = false,,
  Optional[String[1]] $basic_auth_user         = undef,,
  Optional[String[1]] $basic_auth_pass         = undef,,
) {
  include grafana
  $url = "${wombat_cluster_protocol}://${wombat_cluster_host}:${wombat_cluster_port}"
  $datasource = {
    'apiVersion' => 1,
    'datasources' => [
      'name'              => 'Wombat',
      'orgId'             => 1,
      'type'              => 'vertamedia-clickhouse-datasource',
      'access'            => 'proxy',
      'url'               => $url,
      'uid'               => $uid,
      'basicAuth'         => $basic_auth,
      'basicAuthUser'     => $basic_auth_user,
      'basicAuthPassword' => $basic_auth_pass,
      'withCredentials'   => false,
      'isDefault'         => true,
      'jsonData'          => {
        'addCorsHeader'   => false,
        'usePOST'         => true,
        'defaultDatabase' => $database,
      }
    ]
  }

  file { '/etc/grafana/provisioning/datasources/wombat.yml':
    ensure  => file,
    owner   => root,
    group   => grafana,
    mode    => '0640',
    content => $datasources.to_yaml(),
    notify  => Service['grafana-server'],
    require => Package['grafana'],
  }
}
