# frozen_string_literal: true

control 'uek-kernel-not-installed' do
  title 'Check if UEK kernel is not installed and uek repos are disabled'
  describe packages(/kernel-uek/) do
    its('statuses') { should_not cmp 'installed' }
  end

  describe command('yum repolist') do
    its('stdout') { should_not match (/UEK/) }
  end

  describe command('rpm -qa | grep -i uek') do
    its('exit_status') { should eq 1 }
  end
end
