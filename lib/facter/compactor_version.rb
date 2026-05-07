# frozen_string_literal: true

Facter.add(:compactor_version) do
  confine { Facter.value(:kernel) != 'windows' }
  setcode do
    if Facter::Util::Resolution.which('compactor')
      compactor_version = Facter::Util::Resolution.exec('compactor -v 2>&1')
      %r{compactor\s+(\d+(?:\.\d+){2})}.match(compactor_version)[1]
    else
      # Just add a default
      '0.0.0'
    end
  end
end
