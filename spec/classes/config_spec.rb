# frozen_string_literal: true

require 'spec_helper'

describe 'wombat::datastore' do
  let(:node) { 'foobar.example.com' }
  let(:params) { {} }

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }

        it do
          %w[
            clickhouse-client
            wombat-import
            python3-psycopg2
            python3-gear
            dns-stats-inspector
          ].each do |package|
            is_expected.to contain_package(package)
          end
        end

        it { is_expected.to contain_file('/etc/wombat').with_ensure('directory') }
        it { is_expected.to contain_file('/var/pg_wal').with_ensure('directory') }

        it do
          is_expected.to contain_file(
            '/etc/wombat/wombat.cfg'
          ).with_ensure('file').with_content(
            %r{path=/srv/wombat}
          ).with_content(
            %r{incoming_dir_pattern=\*/\*/incoming}
          ).with_content(
            %r{reload_dir_pattern=\*/\*/cbor}
          ).with_content(
            %r{pcap_dir_pattern=\*/\*/pcap}
          ).with_content(
            %r{database=wombat}
          ).with_content(
            %r{user=wombat}
          ).with_content(
            %r{\[clickhouse\]\n
            servers=localhost\n
            dbdir=/var/lib/clickhouse/\n
            import-server=localhost\n
            node-shard-default=auto\n
            user=wombat\n
            }x
          ).with_content(
            %r{keys=gear,root}
          ).with_content(
            %r{
            \[logger_root\]\n
            level=INFO\n
            handlers=syslog\n
            }x
          ).with_content(
            %r{
            \[logger_gear\]\n
            level=ERROR\n
            qualname=gear\n
            propagate=0\n
            handlers=syslog\n
            }x
          )
        end
      end

      describe 'Change Defaults' do
        context 'packages' do
          before { params.merge!(packages: ['foobar']) }

          it { is_expected.to compile }
          it { is_expected.to contain_package('foobar') }
        end
      end
    end
  end
end
