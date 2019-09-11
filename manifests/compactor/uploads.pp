# == Class:wombat::compactor::upload
# @summary wrapper for the upload of compactor files using puppet-file_upload module
#
# @param destination_base_path Path to copy files to on destination host
# @param service Service name been used
# @param bwlimit Set the limit speed for the upload
# @param uploads Data structure for upload information
#
class wombat::compactor::uploads (
  String                                     $destination_base_path,
  String                                     $service,
  Integer[0,10000]                           $bwlimit,
  Hash[String[1], Wombat::Compactor::Upload] $uploads,
) {
  include file_upload
  $destination_path = defined('$::node_short_name') ? {
    true    => "${destination_base_path}/${service}/${::node_short_name}/incoming",
    default => "${destination_base_path}/${service}/${::hostname}/incoming",
  }
  $uploads.each |String $name, Hash $config| {
    file_upload::upload {$name:
      bwlimit             => $bwlimit,
      destination_path    => $destination_path,
      destination_host    => $config['destination_host'],
      patterns            => $config['patterns'],
      remove_source_files => $config['remove_source_files'],
      ssh_key_source      => $config['ssh_key_source'],
      ssh_user            => $config['ssh_user'],
      create_parent       => $config['create_parent'],
      minute_frequency    => $config['minute_frequency'],
    }
  }
}
