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
          [
            'clickhouse-client',
            'python3-wombat-server',
            'python3-psycopg2',
            'python3-gear',
            'dns-stats-inspector',
            'dns-stats-cdnsdumper',
          ].each do |package|
            is_expected.to contain_package(package)
          end
        end
        it { is_expected.to contain_file('/etc/wombat').with_ensure('directory') } 
        it { is_expected.to contain_file('/var/pg_wal').with_ensure('directory') } 
        it do
          is_expected.to contain_file('/etc/wombat/tsv-clickhouse.tpl').with(
            ensure: 'file',
            source: 'puppet:///modules/wombat/etc/wombat/tsv-clickhouse.tpl',
          )
        end
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
            %r{host=localhost}
          ).with_content(
            %r{servers=localhost}
          ).with_content(
            %r{keys=root,gear}
          ).with_content(
            %r{
            \[logger_root\]\n
            level=DEBUG\n
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
          before(:each) { params.merge!(packages: ['foobar']) }
          it { is_expected.to compile }
          it { is_expected.to contain_package('foobar') }
        end
        context 'conf_dir' do
          before(:each) { params.merge!(conf_dir: '/foo/bar') }
          it { is_expected.to compile }
          it { is_expected.to contain_file('/foo/bar/tsv-clickhouse.tpl') }
          it { is_expected.to contain_file('/foo/bar/wombat.cfg') }
        end
        context 'clickhouse_template' do
          before(:each) do
            params.merge!(clickhouse_template: 'puppet:///modules/foo/bar')
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/tsv-clickhouse.tpl').with(
              ensure: 'file',
              source: 'puppet:///modules/foo/bar',
            )
          end
        end
        context 'data_path' do
          before(:each) { params.merge!(data_path: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{path=/foo/bar}
            )
          end
        end
        context 'incoming_dir_pattern' do
          before(:each) { params.merge!(incoming_dir_pattern: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{incoming_dir_pattern=foobar}
            )
          end
        end
        context 'reload_dir_pattern' do
          before(:each) { params.merge!(reload_dir_pattern: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{reload_dir_pattern=foobar}
            )
          end
        end
        context 'pcap_dir_pattern' do
          before(:each) { params.merge!(pcap_dir_pattern: 'foobar') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{pcap_dir_pattern=foobar}
            )
          end
        end
        context 'db_name' do
          before(:each) { params.merge!(db_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{database=foobar}
            )
          end
        end
        context 'db_user' do
          before(:each) { params.merge!(db_user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{user=foobar}
            )
          end
        end
        context 'db_host' do
          before(:each) { params.merge!(db_host: 'foo.bar') }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{host=foo.bar}
            )
          end
        end
        context 'clickhouse_servers' do
          before(:each) { params.merge!(clickhouse_servers: ['foo', 'bar']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{servers=foo,bar}
            )
          end
        end
        context 'loggers' do
          before(:each) do
            params.merge!(
              loggers: {
                'foobar' => {
                  'level' => 'INFO',
                  'propagate' => true,
                  'qualname' => 'foobar',
                  'handlers' => 'foobar',
                },
              }
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/wombat/wombat.cfg').with_content(
              %r{
              \[logger_foobar\]\n
              level=INFO\n
              qualname=foobar\n
              handlers=foobar\n
              }x
            )
          end
        end
      end
      describe 'check bad type' do
        context 'packages' do
          before(:each) { params.merge!(packages: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'conf_dir' do
          before(:each) { params.merge!(conf_dir: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'clickhouse_template' do
          before(:each) { params.merge!(clickhouse_template: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'data_path' do
          before(:each) { params.merge!(data_path: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'incoming_dir_pattern' do
          before(:each) { params.merge!(incoming_dir_pattern: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'reload_dir_pattern' do
          before(:each) { params.merge!(reload_dir_pattern: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'pcap_dir_pattern' do
          before(:each) { params.merge!(pcap_dir_pattern: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_name' do
          before(:each) { params.merge!(db_name: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_user' do
          before(:each) { params.merge!(db_user: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_host' do
          before(:each) { params.merge!(db_host: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'clickhouse_servers' do
          before(:each) { params.merge!(clickhouse_servers: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'loggers' do
          before(:each) { params.merge!(loggers: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
