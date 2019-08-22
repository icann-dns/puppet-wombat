# @summary installs the required files for the rssac publishing 
#
# @param packages packages to install
#
class wombat::rssacd (
  Array[String[1]]                $packages,
) {
  ensure_packages($packages)
  service { 'wombat-rssac':
    ensure => running,
    enable => true,
  }
}
