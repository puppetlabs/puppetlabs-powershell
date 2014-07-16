#powershell

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with powershell](#setup)
    * [Beginning with powershell](#beginning-with-powershell)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

This module adds a new exec provider capable of executing PowerShell commands. 

##Module Description

Puppet provides a built-in `exec` type that is capable of executing commands. This module adds a `powershell` provider to the `exec` type,  which enables all of the `exec` parameters, such as `creates`, `onlyif`, `unless`, etc. This module is particularly helpful if you need to run PowerShell commands but don't know the details about how PowerShell is executed, since you can technically run PowerShell commands in Puppet without the module.

##Setup

###Beginning with powershell

The powershell module adapts the Puppet
[exec](http://docs.puppetlabs.com/references/stable/type.html#exec)
resource to run PowerShell commands. To get started with the module, simply install it and declare 'powershell' in `provider` with the applicable command.

```
    exec { 'RESOURCENAME':
      command   => '$(SOMECOMMAND)',
      provider  => powershell,
    }
```

##Usage

When using `exec` resources with the `powershell` provider, the `command` parameter must be single-quoted to prevent Puppet from interpolating `$(..)`. 

For instance, if you wanted to rename the Guest account

```
    exec { 'rename-guest':
      command   => '$(Get-WMIObject Win32_UserAccount -Filter "Name=\'guest\'").Rename("new-guest")',
      unless    => 'if (Get-WmiObject Win32_UserAccount -Filter "Name=\'guest\'") { exit 1 }',
      provider  => powershell,
    }
```

Note that the example uses the `unless` parameter to make the resource idempotent. The `command` is only executed if the Guest account does not exist, as indicated by
`unless` returning 0.

**Note:** PowerShell variables, e.g. `$_`, must be escaped in puppet manifests either using backslashes or single quotes.

Alternatively, you can put the PowerShell code for the `command`, `onlyif`, and `unless` parameters into separate templates and then invoke the template function in the resource.

```
exec { 'rename-guest':
  command   => template('guest/rename-guest.ps1'),
  onlyif    => template('guest/guest-exists.ps1'),
  provider  => powershell,
  logoutput => true,
}
```
Each template is a PowerShell script, 

```
$obj = $(Get-WMIObject Win32_UserAccount -Filter "Name='Guest'")
$obj.Rename("OtherGuest")
```

This has the added benefit of not requiring escaping '$' in the PowerShell code.

##Reference

Since the powershell module is a provider for `exec` it enables the same parameters as [`exec`](http://docs.puppetlabs.com/references/stable/type.html#exec) for PowerShell.

###Provider: powershell

####Parameters

* **command** - The actual PowerShell command to execute. Must either be fully qualified or a search path for the command must be provided. 
* **creates** - The file to look for before running the command. The command will only run if the file doesn’t exist. *Note:* This parameter will not create a file, it will simply look for one.
* **cwd** - The directory from which to run the command.
* **environment** - Additional environment variables to set for a command. Multiple entries should be in an array.
* **group** - The group to run the command as.  
* **logoutput** - Whether to log command output in addition to logging the exit code. Valid values are 'true', 'false', and 'on_failure'. Defaults to 'on_failure, which only logs the output when the command has an exit code that does not match any value specified by the returns attribute. 
* **onlyif** - Only run the exec if the command returns 0.
* **path** - The search path used for command execution.
* **refresh** - How to refresh the command.
* **refreshonly** -  Used with `subscribe` and `notify` [metaparameters](http://docs.puppetlabs.com/references/latest/metaparameter.html) to refresh the command only when a dependent object is changed. Valid values are 'true' and 'false'.
* **returns** - The expected return code(s). An error will be returned if the executed command returns something else. Defaults to 0. Can be specified as an array of acceptable return codes or a single value.
* **timeout** - The maximum time the command should take.
* **tries** - The number of times execution of the command should be tried. Defaults to '1'. 
* **try_sleep** - The time to sleep in seconds between `tries`.
* **umask** - The umask to be used while executing the command.
* **unless** - The `exec` will run unless the command returns 0.

##Limitations

 * This module requires PowerShell to be installed and the `powershell.exe` to be available in the system PATH.
 * Only supported on Windows Server 2003 and above, and Windows 7 and 8

##Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can’t access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

You can read the complete module contribution guide [on the Puppet Labs wiki.](http://projects.puppetlabs.com/projects/module-site/wiki/Module_contributing)
