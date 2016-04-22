test_name 'Install modules' do
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  staging = { :module_name => 'puppetlabs-powershell' }
  local = { :module_name => 'powershell', :source => proj_root }

  hosts.each do |host|
    step 'Install PowerShell Module'
    # in CI allow install from staging forge, otherwise from local
    install_dev_puppet_module_on(host, options[:forge_host] ? staging : local)
  end
end
