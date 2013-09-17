# powershell

##Overview

This module adds an `exec` provider allowing Puppet to execute PowerShell commands.

##Module Description

Puppet provides a built-in `exec` type that is capable of executing commands. This module adds a `powershell` provider for the `exec` type, and as such, supports all of the `exec` parameters like `creates`, `onlyif`, `unless`, etc.

##Setup

###Beginning with powershell

The best way to install this module is with the `puppet module`
subcommand or the `puppet-module` Gem.  On your puppet master, execute
the following command, optionally specifying your puppet master's
`modulepath` in which to install the module:

    $ puppet module install [--modulepath <path>] joshcooper/powershell

See the section [Installing Modules](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html#installing-modules-1) for more information.

##Usage

To rename the `Guest` account:

    exec { 'rename-guest':
      command   => '$(Get-WMIObject Win32_UserAccount -Filter "Name=\'guest\'").Rename("new-guest")',
      unless    => 'if (Get-WmiObject Win32_UserAccount -Filter "Name=\'guest\'") { exit 1 }',
      provider  => powershell,
    }

Notice that the `command` parameter is single-quoted to prevent puppet
from interpolating `$(..)`. Also note that the example uses the
`unless` parameter to make the resource idempotent. The `command` is
only executed if the `Guest` account does not exist, as indicated by
`unless` returning 0.

The powershell provider also supports the `onlyif` exec parameter. See
the
[exec](http://docs.puppetlabs.com/references/stable/type.html#exec)
resource for more information about these parameters.

##Limitations

 * This module requires PowerShell to be installed and the `powershell.exe` to be available in the system `PATH`.
 * Be careful when using PowerShell variables, e.g. `$_`, as they must be escaped in puppet manifests either using backslashes or single quotes.

##License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)


