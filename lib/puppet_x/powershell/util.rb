module PuppetX
  module PowerShell
    module Util
      def lib_loaded?
        defined?(Pwsh::Manager)
      end
      module_function :lib_loaded?
    
      def load_lib
        begin
          require 'ruby-pwsh'
        rescue LoadError
          Puppet.error 'Could not load the "ruby-pwsh" library; is puppetlabs-pwshlib installed?'
        end
      end
      module_function :load_lib
    end
  end
end