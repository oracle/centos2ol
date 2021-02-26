# frozen_string_literal: true

control 'uek-kernel-installed' do
  title 'Check if UEK kernel is installed and uek repos are enabled'
  describe packages(/kernel-uek/) do
    its('statuses') { should cmp 'installed' }
  end

  describe command('yum repolist') do
    its('stdout') { should match (/UEK/) }
  end

  describe command('rpm -qa | grep -i uek') do
    its('exit_status') { should eq 0 }
  end
end
