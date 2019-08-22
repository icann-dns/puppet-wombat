# @summary installs the required files for the rssac publishing 
#
# @param packages packages to install
# @param web_root location for the web_root
# @param output_dir output dir for the rssac reports
# @param report type of report to perform
# @param server server name
# @param report_server_name service FQDN
#
class wombat::rssac_report (
  Array[String[1]]                $packages,
  Stdlib::Unixpath                $web_root,
  Stdlib::Unixpath                $output_dir,
  String[1]                       $report,
  String[1]                       $server,
  Stdlib::Host                    $report_server_name,
) {
  ensure_packages($packages)
  $_directories = [ $web_root , $web_root/$output_dir ]
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', mode => '0755' }
  )
  cron {'wombat-rssac-reports':
    command => "/usr/bin/wombat-rssac-reports --output-dir ${output_dir} --report ${report} --server ${server} --report-server-name ${report_server_name}",
    user    => 'root',
    minute  => '0',
    hour    => '1',
  }
}q
