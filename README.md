Microsoft Windows PowerShell module for Puppet
==============================================

This module adds an `exec` provider allowing Puppet to execute PowerShell commands.

Installation
------------

The best way to install this module is with the `puppet module`
subcommand or the `puppet-module` Gem.  On your puppet master, execute
the following command, optionally specifying your puppet master's
`modulepath` in which to install the module:

    $ puppet module install [--modulepath <path>] joshcooper/powershell

See the section [Installing Modules](http://docs.puppetlabs.com/puppet/2.7/reference/modules_installing.html#installing-modules-1) for more information.

Installation from source
------------------------

If you'd like to install this module from source, please simply clone a copy
into your puppet master's `modulepath`.  Here is an example of how to do so for
Puppet Enterprise:

    $ cd /etc/puppetlabs/puppet/modules $ git clone
    git://github.com/joshcooper/puppetlabs-powershell.git powershell


Examples
--------

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

License
-------

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)

Contact
-------

 * Josh Cooper <josh@puppetlabs.com>

Known Issues
============

 * This module requires PowerShell to be installed and the `powershell.exe` to be available in the system `PATH`.
 * Be careful when using PowerShell variables, e.g. `$_`, as they must be escaped in puppet manifests either using backslashes or single quotes.
