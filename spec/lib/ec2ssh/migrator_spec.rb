require 'spec_helper'
require 'ec2ssh/migrator'

describe Ec2ssh::Migrator do
  include FakeFS::SpecHelpers

  subject(:migrator) { described_class.new '/dotfile' }

  before do
    File.open('/dotfile', 'w') {|f| f.write dotfile_str }
  end

  context 'from version 2' do
    let(:dotfile_str) { <<-END }
---
path: /path/to/ssh/config
aws_keys:
  key1:
    access_key_id: ACCESS_KEY1
    secret_access_key: SECRET1
  key2:
    access_key_id: ACCESS_KEY2
    secret_access_key: SECRET2
regions:
- ap-northeast-1
- us-east-1
    END

    let(:new_dotfile_str) { <<-END }
path '/path/to/ssh/config'
aws_keys(
  key1: { access_key_id: 'ACCESS_KEY1', secret_access_key: 'SECRET1' },
  key2: { access_key_id: 'ACCESS_KEY2', secret_access_key: 'SECRET2' }
)
regions 'ap-northeast-1', 'us-east-1'

# Ignore unnamed instances
reject {|instance| !instance.tags['Name'] }

# You can use methods of AWS::EC2::Instance.
# See http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/EC2/Instance.html
host_line <<EOS
Host <%= tags['Name'] %>.<%= availability_zone %>
  HostName <%= dns_name || private_ip_address %>
EOS

# ---
# path: /path/to/ssh/config
# aws_keys:
#   key1:
#     access_key_id: ACCESS_KEY1
#     secret_access_key: SECRET1
#   key2:
#     access_key_id: ACCESS_KEY2
#     secret_access_key: SECRET2
# regions:
# - ap-northeast-1
# - us-east-1
    END

    it { expect(migrator.check_version).to eq('2') }
    it { expect(migrator.migrate_from_2).to eq(new_dotfile_str) }
  end
end
