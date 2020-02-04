# @summary installs the required files for the rssac publishing 
#
# @param packages packages to install
# @param report type of report to perform
# @param server server name
# @param report_server_name service FQDN
#
class wombat::rssac_report (
  Array[String[1]]                $packages,
  String[1]                       $report,
  String[1]                       $server,
  Stdlib::Host                    $report_server_name,
) {
  ensure_packages($packages)
  include wombat::config
  $_directories = [ $::wombat::config::rssac_outdir ]
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', owner => $wombat::config::user, mode => '0755' }
  )
  cron {'wombat-rssac-reports':
    command => "/usr/bin/wombat-rssac-reports --output-dir ${::wombat::config::rssac_outdir} --report ${report} --server ${server} --report-server-name ${report_server_name}",
    user    => $wombat::config::user,
    minute  => '0',
    hour    => '1',
    require => Package[$packages],
  }
}
