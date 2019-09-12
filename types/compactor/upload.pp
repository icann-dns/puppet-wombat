type Wombat::Compactor::Upload = Struct[{
  destination_host    => Stdlib::Host,
  patterns            => Array[String],
  remove_source_files => Boolean,
  ssh_key_source      => Stdlib::Filesource,
  ssh_user            => String[1],
  create_parent       => Boolean,
  minute_frequency    => Array[minute],
}]
