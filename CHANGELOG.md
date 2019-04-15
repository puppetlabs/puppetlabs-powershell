# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.0] - 2019-04-19

### Added

- Metadata for supporting Windows Server 2019 ([FM-7693](https://tickets.puppetlabs.com/browse/FM-7693))
- Added a 'pwsh' provider for PowerShell Core ([MODULES-8355](https://tickets.puppetlabs.com/browse/MODULES-8355), [MODULES-8356](https://tickets.puppetlabs.com/browse/MODULES-8356), [MODULES-8357](https://tickets.puppetlabs.com/browse/MODULES-8357), [MODULES-8358](https://tickets.puppetlabs.com/browse/MODULES-8358), [MODULES-8359](https://tickets.puppetlabs.com/browse/MODULES-8359))
- Updated metadata for PowerShell Core support (CentOS, Debian, Fedora, OSX and RedHat) ([MODULES-8356](https://tickets.puppetlabs.com/browse/MODULES-8356))

### Changed

- Only initialise constant when not defined ([MODULES-7067](https://tickets.puppetlabs.com/browse/MODULES-7067))

### Fixed

- Improved pipe reading in the PowerShell Manager ([MODULES-8748](https://tickets.puppetlabs.com/browse/MODULES-8748))

## [2.2.0] - 2018-10-29

### Added

- Added support for Puppet 6 ([MODULES-7833](https://tickets.puppetlabs.com/browse/MODULES-7833))

### Changed

- Updated the module to PDK format ([MODULES-7402](https://tickets.puppetlabs.com/browse/MODULES-7402))
- Updated Beaker to version 4 ([MODULES-7658](https://tickets.puppetlabs.com/browse/MODULES-7658))

## [2.1.5] - 2018-05-08

### Added

- Metadata for supporting Windows Server 2016 ([MODULES-4271](https://tickets.puppetlabs.com/browse/MODULES-4271))

### Fixed

- Upgraded message to make .NET Framework requirements clearer when running PowerShell 2.0 ([MODULES-7011](https://tickets.puppetlabs.com/browse/MODULES-7011))
- Fixed timeout handling when the user specifies a timeout parameter value of `0` to substitute the default of 300 seconds ([MODULES-7018](https://tickets.puppetlabs.com/browse/MODULES-7018))

## [2.1.4] - 2017-03-29

### Fixed

- Ensured that the code is able to start the pipes server in a PowerShell process on Windows 2008R2 images ([MODULES-6927](https://tickets.puppetlabs.com/browse/MODULES-6927))
- Updated PowerShell syntax in README examples

## [2.1.3] - 2017-12-08

### Fixed

- Fixed timeouts and zombie process creation ([MODULES-4748](https://tickets.puppetlabs.com/browse/MODULES-4748))
- Corrected PowerShell executable name for experimental cross-platform / PowerShell 6 support ([MODULES-6081](https://tickets.puppetlabs.com/browse/MODULES-6081))

## [2.1.2] - 2017-07-27

### Fixed

- Fixed Global Warning variable ([MODULES-5224](https://tickets.puppetlabs.com/browse/MODULES-5224))
- Moved the PowerShell template file to stop it conflicting with the DSC module ([MODULES-5228](https://tickets.puppetlabs.com/browse/MODULES-5228))

## [2.1.1] - 2017-07-07

### Added

- Rake tasks for release automation
- Experimental support for non-Windows Support (CentOS, Ubuntu) ([MODULES-3945](https://tickets.puppetlabs.com/browse/MODULES-3945))

### Fixed

- Updated documentation ([DOC-2960](https://tickets.puppetlabs.com/browse/DOC-2960))
- Updated metadata for Puppet 4 and Puppet 5 ([MODULES-4528](https://tickets.puppetlabs.com/browse/MODULES-4528), [MODULES-4822](https://tickets.puppetlabs.com/browse/MODULES-4822), [MODULES-5144](https://tickets.puppetlabs.com/browse/MODULES-5144))
- Dispose runspace on pipe close ([MODULES-4754](https://tickets.puppetlabs.com/browse/MODULES-4754))
- Removed rspec configuration for win32_console ([MODULES-4976](https://tickets.puppetlabs.com/browse/MODULES-4976))
- Provider will now respect the environment parameter ([MODULES-4138](https://tickets.puppetlabs.com/browse/MODULES-4138))
- Return available UI Output on error ([MODULES-5145](https://tickets.puppetlabs.com/browse/MODULES-5145))

## [2.1.0] - 2016-11-17

### Fixed

- Support for Windows 2016/WMF 5.1 using named pipes ([MODULES-3690](https://tickets.puppetlabs.com/browse/MODULES-3690))
- Fixed documentation for herestring ([DOC-2960](https://tickets.puppetlabs.com/browse/DOC-2960))

### Added

- Speed improvements to the PowerShell manager ([MODULES-3690](https://tickets.puppetlabs.com/browse/MODULES-3690))

## [2.0.3] - 2016-10-05

### Added

- The ability to set the current working directory ([MODULES-3565](https://tickets.puppetlabs.com/browse/MODULES-3565))

### Fixed

- Miscellaneous fixes to improve reliability
- Fixed capture exit codes when executing external scripts ([MODULES-3399](https://tickets.puppetlabs.com/browse/MODULES-3399))
- Fixed respect user specified timeout ([MODULES-3709](https://tickets.puppetlabs.com/browse/MODULES-3709))
- Improved handling of user code exceptions ([MODULES-3443](https://tickets.puppetlabs.com/browse/MODULES-3443))
- Fixed output line and stacktrace of user code exception ([MODULES-3839](https://tickets.puppetlabs.com/browse/MODULES-3839))
- Improved the PowerShell host so that it is more resilient to failure ([MODULES-3875](https://tickets.puppetlabs.com/browse/MODULES-3875))
- Fixed race condition in threading with the PowerShell host ([MODULES-3144](https://tickets.puppetlabs.com/browse/MODULES-3144))
- Modified tests to detect differences in PowerShell error text ([MODULES-3443](https://tickets.puppetlabs.com/browse/MODULES-3443))
- Documented how to handle exit codes ([MODULES-3588](https://tickets.puppetlabs.com/browse/MODULES-3588))

## [2.0.2] - 2016-07-12

### Added

- Noticable speed increase by reducing the time start for a PowerShell command ([MODULES-3406](https://tickets.puppetlabs.com/browse/MODULES-3406))
- Tests for try/catch ([MODULES-2634](https://tickets.puppetlabs.com/browse/MODULES-2634))

### Fixed

- Fixed minor bugs in tests ([MODULES-3347](https://tickets.puppetlabs.com/browse/MODULES-3347))
- Fixed bug with older ruby (1.8)

## [2.0.1] - 2016-05-24

### Fixed

- Updated the PowerShell manager so that it does not conflict with the PowerShell Manager in the Puppet DSC module ([FM-5240](https://tickets.puppetlabs.com/browse/FM-5240))

## [2.0.0] - 2016-05-17

### Changed

- Major performance improvement by sharing a single PowerShell session, instead of creating a new PowerShell session per command. This change no longer writes temporary scripts to file system. ([MODULES-2962](https://tickets.puppetlabs.com/browse/MODULES-2962))

### Fixed

- Updated test suites with later versions ([MODULES-2452](https://tickets.puppetlabs.com/browse/MODULES-2452), [MODULES-3011](https://tickets.puppetlabs.com/browse/MODULES-3011))
- Cleaned up documentation ([MODULES-3192](https://tickets.puppetlabs.com/browse/MODULES-3192))
- Removed extra verbose output

## [1.0.6] - 2015-12-08

### Fixed

- Fixed testing bug when testing on Puppet 3+ on Windows Server 2003 ([MODULES-2443](https://tickets.puppetlabs.com/browse/MODULES-2443))

## [1.0.5] - 2015-07-28

### Added

- Metadata for Puppet 4 and PE 2015.2.0 ([FM-2752](https://tickets.puppetlabs.com/browse/FM-2752))

### Fixed

- Minor testing bug fixes ([MODULES-2207](https://tickets.puppetlabs.com/browse/MODULES-2207))
- Readme cleanup ([DOC-1497](https://tickets.puppetlabs.com/browse/DOC-1497))

## [1.0.4] 2014-11-04

### Fixed

- Fixed issues URL in metadata.json

### Added

- Future Parser testing support ([FM-1519](https://tickets.puppetlabs.com/browse/FM-1519))

## [1.0.3] - 2014-08-25

### Fixed

- Updated tests to verify that PowerShell continues to function on x64-native ruby

## [1.0.2] - 2014-07-15

### Fixed

- Updated metadata.json so that the module can be uninstalled and upgraded via the puppet module command

## [1.0.1]

### Fixed

- Fixed issue with metadata and PE version requirement

[Unreleased]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.3.0...master
[2.3.0]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.5...2.2.0
[2.1.5]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.4...2.1.5
[2.1.4]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.3...2.1.4
[2.1.3]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.2...2.1.3
[2.1.2]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.1...2.1.2
[2.1.1]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.3...2.1.0
[2.0.3]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.2...2.0.3
[2.0.2]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.6...2.0.0
[1.0.6]: https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.5...1.0.6
[1.0.5]: https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.0...1.0.1
