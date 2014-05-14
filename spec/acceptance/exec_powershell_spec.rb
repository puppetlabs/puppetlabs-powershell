require 'spec_helper_acceptance'

describe 'powershell provider:', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  shared_context  'powershell plugin sync' do
    copy_root_module_to(master, {:module_name => 'powershell'})
    on agents, puppet("plugin download --server #{master}")
  end

  describe 'should run successfully' do
   include_context 'powershell plugin sync'
    p1 = <<-MANIFEST
exec{'TestPowershell':
  command   => 'Get-Process > c:/process.txt',
  unless	=> 'if(!(test-path "c:/process.txt")){exit 1}',
  provider  => powershell,
}
    MANIFEST
    it 'should not error on first run' do
      # Run it twice and test for idempotency
      apply_manifest(p1, :catch_failures => true)
    end
    it 'should be idempotent' do
      expect(apply_manifest(p1, :catch_failures => true).exit_code).to be_zero
    end

  end

  describe 'should be able to access the files after execution' do
    include_context 'powershell plugin sync'
    p2 = <<-MANIFEST
exec{"TestPowershell":
  command   => 'Get-Service *puppet* | Out-File -FilePath C:/services.txt -Encoding UTF8',
  provider  => powershell
}
    MANIFEST

    describe file('c:/services.txt') do
      it "should create file c:/services.txt" do
        apply_manifest(p2, :catch_failures => true)
      end
      it { should be_file }
      its(:content) { should match /puppet/ }
    end
  end

  describe 'should be able to execute a ps1 file provided' do
    include_context 'powershell plugin sync'
    p2 = <<-MANIFEST
    file{'c:/services.ps1':
      content => '#{File.open(File.join(File.dirname(__FILE__), 'files/services.ps1')).read()}'
    }
    exec{"TestPowershellPS1":
      command   => 'c:/services.ps1',
      provider  => powershell,
      require   => File['c:/services.ps1']
    }
    MANIFEST
    describe "it should execute the file without error" do
      apply_manifest(p2, :catch_failures => true)
    end
    describe file('c:/temp/services.csv') do
      it { should be_file }
      its(:content) { should match /puppet/ }
    end
  end

  describe 'should execute using 64 bit powershell' do
    p3 = <<-MANIFEST
     $maxArchNumber = $::architecture? {
      /(?i)(i386|i686|x86)$/	=> 4,
      /(?i)(x64|x86_64)/=> 8,
      default => 0
    }
    exec{'Test64bit':
	    command => "if([IntPtr]::Size -eq $maxArchNumber) {exit 0}else{exit 1}",
	    provider => powershell
    }
    MANIFEST
    it { apply_manifest(p3, :catch_failures => true) }
  end

end
