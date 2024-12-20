# @summary installs the required files for the rssac publishing
#
# @param packages packages to install
# @param report type of report to perform
# @param server server name
# @param report_file_prefix prefix for the generated files
# @param report_server_name service FQDN
#
class wombat::rssac_report (
  Array[String[1]] $packages,
  String[1]        $report,
  String[1]        $server,
  String[1]        $report_file_prefix,
  Stdlib::Host     $report_server_name,
) {
  ensure_packages($packages)
  include wombat::config
  $_directories = [$wombat::config::rssac_outdir]
  $base_command = @("COMMAND"/L)
    /usr/bin/wombat-rssac-reports --output-dir ${wombat::config::rssac_outdir} \
      --report ${report} --server ${server} --report-file-prefix ${report_file_prefix} \
      --report-server-name ${report_server_name}
    | COMMAND
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', owner => $wombat::config::user, mode => '0755' }
  )
  cron { 'wombat-rssac-reports-yaml':
    command => "${base_command} --no-plots",
    user    => $wombat::config::user,
    minute  => '0',
    hour    => '1',
    require => Package[$packages],
  }
  cron { 'wombat-rssac-reports-plots':
    command => "${base_command} --no-yaml",
    user    => $wombat::config::user,
    minute  => '30',
    hour    => '1',
    require => Package[$packages],
  }
}
