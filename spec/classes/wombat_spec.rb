require 'spec_helper'

describe 'wombat' do
  let(:node) { 'wombat.example.com' }
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
          is_expected.to contain_file(
            '/etc/odbc.ini'
          ).with_ensure('file').with_content(
            %r{Database\s+=\s+wombat}
          ).with_content(
            %r{Servername\s+=\s+localhost}
          ).with_content(
            %r{UserName\s+=\s+wombat}
          ).with_content(
            %r{Password\s+=\s+wombat}
          ).with_content(
            %r{Port\s+=\s+5432}
          )
        end
        it do
          is_expected.to contain_file(
            '/usr/local/share/wombat_server.whl'
          ).with_ensure('file').with_source(
            'puppet:///modules/wombat/share/wombat_server.whl'
          )
        end
        it do
          is_expected.to contain_exec(
            '/usr/bin/pip3 install /usr/local/share/wombat_server.whl'
          ).with(
            refreshonly: true,
            subscribe: 'File[/usr/local/share/wombat_server.whl]',
          )
        end
      end
      describe 'Change Defaults' do
        context 'packages' do
          before(:each) { params.merge!(packages: ['foobar', 'python3-pip']) }
          it { is_expected.to compile }
          it { is_expected.to contain_package('foobar') }
        end
        context 'db_host' do
          before(:each) { params.merge!(db_host: 'foo.bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/odbc.ini'
            ).with_ensure('file').with_content(
              %r{Servername\s+=\s+foo.bar}
            )
          end
        end
        context 'db_name' do
          before(:each) { params.merge!(db_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/odbc.ini'
            ).with_ensure('file').with_content(
              %r{Database\s+=\s+foobar}
            )
          end
        end
        context 'db_username' do
          before(:each) { params.merge!(db_username: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/odbc.ini'
            ).with_ensure('file').with_content(
              %r{UserName\s+=\s+foobar}
            )
          end
        end
        context 'db_password' do
          before(:each) { params.merge!(db_password: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/odbc.ini'
            ).with_ensure('file').with_content(
              %r{Password\s+=\s+foobar}
            )
          end
        end
        context 'db_port' do
          before(:each) { params.merge!(db_port: 42) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/odbc.ini'
            ).with_ensure('file').with_content(
              %r{Port\s+=\s+42}
            )
          end
        end
        context 'odbc_file' do
          before(:each) { params.merge!(odbc_file: '/foo/bar') }
          it { is_expected.to compile }
          it { is_expected.to contain_file('/foo/bar').with_ensure('file') }
        end
        context 'package_src' do
          before(:each) { params.merge!(package_src: 'puppet:///modules/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/share/wombat_server.whl'
            ).with_ensure('file').with_source(
              'puppet:///modules/foobar'
            )
          end
        end
      end
      describe 'check bad type' do
        context 'packages' do
          before(:each) { params.merge!(packages: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_host' do
          before(:each) { params.merge!(db_host: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_name' do
          before(:each) { params.merge!(db_name: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_username' do
          before(:each) { params.merge!(db_username: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_password' do
          before(:each) { params.merge!(db_password: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'db_port' do
          before(:each) { params.merge!(db_port: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'odbc_file' do
          before(:each) { params.merge!(odbc_file: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'package_src' do
          before(:each) { params.merge!(package_src: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
