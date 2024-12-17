<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v6.0.1](https://github.com/puppetlabs/puppetlabs-powershell/tree/v6.0.1) - 2024-12-17

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v6.0.0...v6.0.1)

### Fixed

- (CAT-2180) Upgrade rexml to address CVE-2024-49761 [#425](https://github.com/puppetlabs/puppetlabs-powershell/pull/425) ([amitkarsale](https://github.com/amitkarsale))

## [v6.0.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/v6.0.0) - 2023-04-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v5.2.1...v6.0.0)

### Changed

- (CONT-793) - Add Puppet 8/Drop Puppet 6 [#400](https://github.com/puppetlabs/puppetlabs-powershell/pull/400) ([jordanbreen28](https://github.com/jordanbreen28))

## [v5.2.1](https://github.com/puppetlabs/puppetlabs-powershell/tree/v5.2.1) - 2023-04-21

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v5.2.0...v5.2.1)

### Fixed

- pdksync - (CONT-130) - Dropping Support for Debian 9 [#384](https://github.com/puppetlabs/puppetlabs-powershell/pull/384) ([jordanbreen28](https://github.com/jordanbreen28))

## [v5.2.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/v5.2.0) - 2022-10-03

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v5.1.0...v5.2.0)

### Added

- pdksync - (GH-cat-11) Certify Support for Ubuntu 22.04 [#381](https://github.com/puppetlabs/puppetlabs-powershell/pull/381) ([david22swan](https://github.com/david22swan))

### Fixed

- (MAINT) Dropped support for Windows(7,8,2008 + 2008 R2(Server), Fedora(27+28) and OSX OS's(10.12-.14) [#382](https://github.com/puppetlabs/puppetlabs-powershell/pull/382) ([jordanbreen28](https://github.com/jordanbreen28))

## [v5.1.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/v5.1.0) - 2022-06-13

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v5.0.0...v5.1.0)

### Added

- pdksync - (GH-cat-12) Add Support for Redhat 9 [#379](https://github.com/puppetlabs/puppetlabs-powershell/pull/379) ([david22swan](https://github.com/david22swan))
- pdksync - (FM-8922) - Add Support for Windows 2022 [#370](https://github.com/puppetlabs/puppetlabs-powershell/pull/370) ([david22swan](https://github.com/david22swan))
- (IAC-1734) - Certify Debian 11 [#368](https://github.com/puppetlabs/puppetlabs-powershell/pull/368) ([david22swan](https://github.com/david22swan))
- pdksync - (IAC-1753) - Add Support for AlmaLinux 8 [#364](https://github.com/puppetlabs/puppetlabs-powershell/pull/364) ([david22swan](https://github.com/david22swan))
- pdksync - (IAC-1751) - Add Support for Rocky 8 [#363](https://github.com/puppetlabs/puppetlabs-powershell/pull/363) ([david22swan](https://github.com/david22swan))
- (IAC-900) - Certify Ubuntu 20.04 [#359](https://github.com/puppetlabs/puppetlabs-powershell/pull/359) ([david22swan](https://github.com/david22swan))

### Fixed

- pdksync - (GH-iac-334) Remove Support for Ubuntu 14.04/16.04 [#372](https://github.com/puppetlabs/puppetlabs-powershell/pull/372) ([david22swan](https://github.com/david22swan))
- pdksync - (IAC-1598) - Remove Support for Debian 8 [#361](https://github.com/puppetlabs/puppetlabs-powershell/pull/361) ([david22swan](https://github.com/david22swan))

## [v5.0.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/v5.0.0) - 2021-03-02

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v4.1.0...v5.0.0)

### Changed

- pdksync - Remove Puppet 5 from testing and bump minimal version to 6.0.0 [#330](https://github.com/puppetlabs/puppetlabs-powershell/pull/330) ([carabasdaniel](https://github.com/carabasdaniel))

## [v4.1.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/v4.1.0) - 2020-12-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v4.0.0...v4.1.0)

### Added

- Add support for Puppet 7 [#322](https://github.com/puppetlabs/puppetlabs-powershell/pull/322) ([daianamezdrea](https://github.com/daianamezdrea))
- (MODULES-10722) Inherit pipe_timeout from timeout [#321](https://github.com/puppetlabs/puppetlabs-powershell/pull/321) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [v4.0.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/v4.0.0) - 2020-07-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v3.0.1...v4.0.0)

### Changed

- Correct supported Puppet lower bound to 5.5.0 [#282](https://github.com/puppetlabs/puppetlabs-powershell/pull/282) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Added

- (IAC-835) Support added for Debian 10 and CentOS/RHEL 8 [#306](https://github.com/puppetlabs/puppetlabs-powershell/pull/306) ([david22swan](https://github.com/david22swan))

### Fixed

- (MODULES-10539) Remove commands idiom from PowerShell provider [#287](https://github.com/puppetlabs/puppetlabs-powershell/pull/287) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [v3.0.1](https://github.com/puppetlabs/puppetlabs-powershell/tree/v3.0.1) - 2020-01-15

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/v3.0.0...v3.0.1)

### Fixed

- (MODULES-10389) - Safeguard powershell provider loading [#277](https://github.com/puppetlabs/puppetlabs-powershell/pull/277) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [v3.0.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/v3.0.0) - 2020-01-06

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.3.0...v3.0.0)

### Changed

- (FM-8475) Replace library code [#264](https://github.com/puppetlabs/puppetlabs-powershell/pull/264) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (MODULES-9473) Fix Issues Link [#259](https://github.com/puppetlabs/puppetlabs-powershell/pull/259) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-9084) Increase pipe timeout to 180s [#257](https://github.com/puppetlabs/puppetlabs-powershell/pull/257) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [2.3.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.3.0) - 2019-04-22

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.2.0...2.3.0)

### Other

- (MODULES-8924) DOCS Release Review [#254](https://github.com/puppetlabs/puppetlabs-powershell/pull/254) ([clairecadman](https://github.com/clairecadman))
- (MODULES-8924) Prepare module for 2.3.0 release [#253](https://github.com/puppetlabs/puppetlabs-powershell/pull/253) ([glennsarti](https://github.com/glennsarti))
- (WIN-280) add skip() unless pattern to tests [#251](https://github.com/puppetlabs/puppetlabs-powershell/pull/251) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (MODULES-8748) Improve pipe reading in the PowerShell Manager [#250](https://github.com/puppetlabs/puppetlabs-powershell/pull/250) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8359) Remove non-Windows support for powershell provider [#249](https://github.com/puppetlabs/puppetlabs-powershell/pull/249) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8358) Fix typo for EL based test hosts [#248](https://github.com/puppetlabs/puppetlabs-powershell/pull/248) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8358) Add PowerShell manager to pwsh provider [#247](https://github.com/puppetlabs/puppetlabs-powershell/pull/247) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8356) Improve pwsh searching [#246](https://github.com/puppetlabs/puppetlabs-powershell/pull/246) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8532) PDK Update to template SHA 7281db5 [#245](https://github.com/puppetlabs/puppetlabs-powershell/pull/245) ([glennsarti](https://github.com/glennsarti))
- (FM-7693) Add Windows Server 2019 [#243](https://github.com/puppetlabs/puppetlabs-powershell/pull/243) ([glennsarti](https://github.com/glennsarti))
- (maint) Fix module installing in master-agent scenario [#242](https://github.com/puppetlabs/puppetlabs-powershell/pull/242) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8356) Search for pwsh binary [#241](https://github.com/puppetlabs/puppetlabs-powershell/pull/241) ([glennsarti](https://github.com/glennsarti))
- (MODULES-8357) Add cross platform support for pwsh provider [#240](https://github.com/puppetlabs/puppetlabs-powershell/pull/240) ([glennsarti](https://github.com/glennsarti))
- (maint) Update pdk template [#239](https://github.com/puppetlabs/puppetlabs-powershell/pull/239) ([jpogran](https://github.com/jpogran))
- (MODULES-8355) Add pwsh provider [#238](https://github.com/puppetlabs/puppetlabs-powershell/pull/238) ([glennsarti](https://github.com/glennsarti))
- Fix issues in README.md [#237](https://github.com/puppetlabs/puppetlabs-powershell/pull/237) ([pdoconnell](https://github.com/pdoconnell))
- Mergeback for 2.2.0 release [#236](https://github.com/puppetlabs/puppetlabs-powershell/pull/236) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- (MODULES-8120) Prepare module for 2.2.0 release [#235](https://github.com/puppetlabs/puppetlabs-powershell/pull/235) ([glennsarti](https://github.com/glennsarti))
- (MODULES-7067) Only initialise constant when not defined [#224](https://github.com/puppetlabs/puppetlabs-powershell/pull/224) ([btoonk](https://github.com/btoonk))

## [2.2.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.2.0) - 2018-10-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.5...2.2.0)

### Other

- (MODULES-8120) Prepare module for 2.2.0 release [#235](https://github.com/puppetlabs/puppetlabs-powershell/pull/235) ([glennsarti](https://github.com/glennsarti))
- (MODULES-7833) Update module for Puppet 6 [#234](https://github.com/puppetlabs/puppetlabs-powershell/pull/234) ([ThoughtCrhyme](https://github.com/ThoughtCrhyme))
- pdksync - (MODULES-7658) use beaker4 in puppet-module-gems [#233](https://github.com/puppetlabs/puppetlabs-powershell/pull/233) ([tphoney](https://github.com/tphoney))
- pdksync - (MODULES-7658) use beaker3 in puppet-module-gems [#232](https://github.com/puppetlabs/puppetlabs-powershell/pull/232) ([tphoney](https://github.com/tphoney))
- (MOUDLES-7402) PDK Convert the module [#231](https://github.com/puppetlabs/puppetlabs-powershell/pull/231) ([glennsarti](https://github.com/glennsarti))
- (PDK-1035) Remove the rspec-puppet pin [#230](https://github.com/puppetlabs/puppetlabs-powershell/pull/230) ([rodjek](https://github.com/rodjek))
- Mergeback release into master [#229](https://github.com/puppetlabs/puppetlabs-powershell/pull/229) ([glennsarti](https://github.com/glennsarti))

## [2.1.5](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.1.5) - 2018-05-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.4...2.1.5)

### Other

- (MODULES-7109) CHANGELOG edits [#228](https://github.com/puppetlabs/puppetlabs-powershell/pull/228) ([clairecadman](https://github.com/clairecadman))
- (MODULES-7109) Release Prep [#227](https://github.com/puppetlabs/puppetlabs-powershell/pull/227) ([RandomNoun7](https://github.com/RandomNoun7))
- (MAINT) Update Changelog to KAC Format [#226](https://github.com/puppetlabs/puppetlabs-powershell/pull/226) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-7018) Fix Zero Timeout Behavior [#225](https://github.com/puppetlabs/puppetlabs-powershell/pull/225) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-7033) Kill test unreliable [#223](https://github.com/puppetlabs/puppetlabs-powershell/pull/223) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-7011) Fix .NET upgrade message [#222](https://github.com/puppetlabs/puppetlabs-powershell/pull/222) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-4271) Add Server 2016 to metadata [#221](https://github.com/puppetlabs/puppetlabs-powershell/pull/221) ([glennsarti](https://github.com/glennsarti))
- (maint) Remove errant pry command [#220](https://github.com/puppetlabs/puppetlabs-powershell/pull/220) ([glennsarti](https://github.com/glennsarti))
- (MODULES-6937) Mergeback release to master [#219](https://github.com/puppetlabs/puppetlabs-powershell/pull/219) ([RandomNoun7](https://github.com/RandomNoun7))

## [2.1.4](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.1.4) - 2018-03-29

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.3...2.1.4)

### Other

- (MAINT) Update changelog prior to 2.1.4 release [#218](https://github.com/puppetlabs/puppetlabs-powershell/pull/218) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6937) Release Prep 2.1.4 [#217](https://github.com/puppetlabs/puppetlabs-powershell/pull/217) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6927) Fix Pipe Server on Win 2008r2 [#216](https://github.com/puppetlabs/puppetlabs-powershell/pull/216) ([RandomNoun7](https://github.com/RandomNoun7))
- Revert "(IMAGES-795) 2008r2 template failing PowerShell module tests" [#215](https://github.com/puppetlabs/puppetlabs-powershell/pull/215) ([RandomNoun7](https://github.com/RandomNoun7))
- (IMAGES-795) 2008r2 template failing PowerShell module tests [#214](https://github.com/puppetlabs/puppetlabs-powershell/pull/214) ([RandomNoun7](https://github.com/RandomNoun7))
- (MODULES-6750) Add testmode switcher [#212](https://github.com/puppetlabs/puppetlabs-powershell/pull/212) ([glennsarti](https://github.com/glennsarti))
- (maint) Minor PowerShell syntax updates to README [#209](https://github.com/puppetlabs/puppetlabs-powershell/pull/209) ([Iristyle](https://github.com/Iristyle))
- (maint) Update sync.yaml for new modsync config options [#208](https://github.com/puppetlabs/puppetlabs-powershell/pull/208) ([glennsarti](https://github.com/glennsarti))
- (maint) modulesync cd884db Remove AppVeyor OpenSSL update on Ruby 2.4 [#204](https://github.com/puppetlabs/puppetlabs-powershell/pull/204) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (maint) - modulesync 384f4c1 [#203](https://github.com/puppetlabs/puppetlabs-powershell/pull/203) ([tphoney](https://github.com/tphoney))

## [2.1.3](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.1.3) - 2017-12-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.2...2.1.3)

### Other

- (MODULES-4748) Prevent zombie procs from timeout [#202](https://github.com/puppetlabs/puppetlabs-powershell/pull/202) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MODULES-4748) Increase timeout for opening PowerShell [#201](https://github.com/puppetlabs/puppetlabs-powershell/pull/201) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MODULES-6081) Rename PowerShell executable [#200](https://github.com/puppetlabs/puppetlabs-powershell/pull/200) ([RandomNoun7](https://github.com/RandomNoun7))
- (maint) Add Github Pull Request Template [#199](https://github.com/puppetlabs/puppetlabs-powershell/pull/199) ([jpogran](https://github.com/jpogran))
- (maint) modulesync 892c4cf [#198](https://github.com/puppetlabs/puppetlabs-powershell/pull/198) ([HAIL9000](https://github.com/HAIL9000))
- Release branch merge back for 2.1.2 [#196](https://github.com/puppetlabs/puppetlabs-powershell/pull/196) ([jpogran](https://github.com/jpogran))
- (maint) Modulesync update [#195](https://github.com/puppetlabs/puppetlabs-powershell/pull/195) ([Iristyle](https://github.com/Iristyle))

## [2.1.2](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.1.2) - 2017-07-27

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.1...2.1.2)

### Other

- (MODULES-5308) Prepare for release of version 2.1.2 [#194](https://github.com/puppetlabs/puppetlabs-powershell/pull/194) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5228) Move PowerShell Manager template file [#193](https://github.com/puppetlabs/puppetlabs-powershell/pull/193) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5224) Fix Global Warning variable [#192](https://github.com/puppetlabs/puppetlabs-powershell/pull/192) ([jpogran](https://github.com/jpogran))
- (maint) Update date in Changelog [#191](https://github.com/puppetlabs/puppetlabs-powershell/pull/191) ([glennsarti](https://github.com/glennsarti))
- Mergeback Release 2.1.1 [#190](https://github.com/puppetlabs/puppetlabs-powershell/pull/190) ([jpogran](https://github.com/jpogran))
- (MODULES-5187) mysnc puppet 5 and ruby 2.4 [#189](https://github.com/puppetlabs/puppetlabs-powershell/pull/189) ([eputnam](https://github.com/eputnam))

## [2.1.1](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.1.1) - 2017-07-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.1.0...2.1.1)

### Other

- fix broken link, tidy up punctuation [#188](https://github.com/puppetlabs/puppetlabs-powershell/pull/188) ([jbondpdx](https://github.com/jbondpdx))
- (MODULES-5163) Release prep 2.1.1 [#187](https://github.com/puppetlabs/puppetlabs-powershell/pull/187) ([glennsarti](https://github.com/glennsarti))
- (MODULES-5145) Return available UI Output on error [#185](https://github.com/puppetlabs/puppetlabs-powershell/pull/185) ([Iristyle](https://github.com/Iristyle))
- (MODULES-5144) Prep for puppet 5 [#184](https://github.com/puppetlabs/puppetlabs-powershell/pull/184) ([hunner](https://github.com/hunner))
- (MODULES-4138) Provider will respect the environment parameter [#183](https://github.com/puppetlabs/puppetlabs-powershell/pull/183) ([glennsarti](https://github.com/glennsarti))
- (MODULES-4976) Remove rspec configuration for win32_console [#182](https://github.com/puppetlabs/puppetlabs-powershell/pull/182) ([glennsarti](https://github.com/glennsarti))
- MODULES-4822 puppetlabs-powershell: Update the version compatibility to >= 4.7.0 < 5.0.0 [#180](https://github.com/puppetlabs/puppetlabs-powershell/pull/180) ([marsmensch](https://github.com/marsmensch))
- (MODULES-4754) Dispose runspace on pipe close [#179](https://github.com/puppetlabs/puppetlabs-powershell/pull/179) ([Iristyle](https://github.com/Iristyle))
- [msync] 786266 Implement puppet-module-gems, a45803 Remove metadata.json from locales config [#176](https://github.com/puppetlabs/puppetlabs-powershell/pull/176) ([wilson208](https://github.com/wilson208))
- (MODULES-3945) Add Non Windows PowerShell platform support [#175](https://github.com/puppetlabs/puppetlabs-powershell/pull/175) ([glennsarti](https://github.com/glennsarti))
- [MODULES-4528] Replace Puppet.version.to_f version comparison from spec_helper.rb [#173](https://github.com/puppetlabs/puppetlabs-powershell/pull/173) ([wilson208](https://github.com/wilson208))
- [MODULES-4556] Remove PE requirement from metadata.json [#172](https://github.com/puppetlabs/puppetlabs-powershell/pull/172) ([wilson208](https://github.com/wilson208))
- (maint) stable mergeback [#171](https://github.com/puppetlabs/puppetlabs-powershell/pull/171) ([DavidS](https://github.com/DavidS))
- (MODULES-4098) Sync the rest of the files [#170](https://github.com/puppetlabs/puppetlabs-powershell/pull/170) ([hunner](https://github.com/hunner))
- (MODULES-4263) add blacksmith rake tasks [#168](https://github.com/puppetlabs/puppetlabs-powershell/pull/168) ([eputnam](https://github.com/eputnam))
- (MODULES-4097) Sync travis.yml [#167](https://github.com/puppetlabs/puppetlabs-powershell/pull/167) ([hunner](https://github.com/hunner))
- (FM-5972) Update to next modulesync_configs [dedaf10] [#165](https://github.com/puppetlabs/puppetlabs-powershell/pull/165) ([DavidS](https://github.com/DavidS))
- (FM-5939) removes spec.opts [#164](https://github.com/puppetlabs/puppetlabs-powershell/pull/164) ([eputnam](https://github.com/eputnam))
- Workaround frozen strings on ruby 1.9 [#160](https://github.com/puppetlabs/puppetlabs-powershell/pull/160) ([hunner](https://github.com/hunner))

## [2.1.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.1.0) - 2016-11-17

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.3...2.1.0)

### Other

- (FM-5728) Update Changlog Date [#161](https://github.com/puppetlabs/puppetlabs-powershell/pull/161) ([jpogran](https://github.com/jpogran))
- (MODULES-3632) Update modulesync [#159](https://github.com/puppetlabs/puppetlabs-powershell/pull/159) ([hunner](https://github.com/hunner))
- (FM-5728) Update changelog for 2.1.0 [#157](https://github.com/puppetlabs/puppetlabs-powershell/pull/157) ([jpogran](https://github.com/jpogran))
- (MODULES-3690) PowerShell v2 + .NET Framework less than 3.5 is unsupported for PowerShell Manager [#155](https://github.com/puppetlabs/puppetlabs-powershell/pull/155) ([ferventcoder](https://github.com/ferventcoder))
- DOC-2960: new limitation and a bit of editing  [#154](https://github.com/puppetlabs/puppetlabs-powershell/pull/154) ([bmjen](https://github.com/bmjen))
- DOC-2960: new limitation and a bit of editing [#153](https://github.com/puppetlabs/puppetlabs-powershell/pull/153) ([jbondpdx](https://github.com/jbondpdx))
- (MODULES-3690) Use custom binary pipe IPC [#142](https://github.com/puppetlabs/puppetlabs-powershell/pull/142) ([Iristyle](https://github.com/Iristyle))

## [2.0.3](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.0.3) - 2016-10-05

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.2...2.0.3)

### Other

- (maint) Update changelog and metadata for release [#151](https://github.com/puppetlabs/puppetlabs-powershell/pull/151) ([jpogran](https://github.com/jpogran))
- (maint) Fix multiline stderr capture [#150](https://github.com/puppetlabs/puppetlabs-powershell/pull/150) ([Iristyle](https://github.com/Iristyle))
- (maint) Re-enable PowerShell 2 tests [#149](https://github.com/puppetlabs/puppetlabs-powershell/pull/149) ([Iristyle](https://github.com/Iristyle))
- (MODULES-3443) Modify error test for differences in Powershell version [#148](https://github.com/puppetlabs/puppetlabs-powershell/pull/148) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3144) Fix race condition draining pipes [#147](https://github.com/puppetlabs/puppetlabs-powershell/pull/147) ([Iristyle](https://github.com/Iristyle))
- (maint) Merge master down to stable [#146](https://github.com/puppetlabs/puppetlabs-powershell/pull/146) ([jpogran](https://github.com/jpogran))
- (MODULES-3144) Drain stdout / stderr in separate threads [#145](https://github.com/puppetlabs/puppetlabs-powershell/pull/145) ([Iristyle](https://github.com/Iristyle))
- (MODULES-3875) Improve PowerShellManager resilience to failure [#144](https://github.com/puppetlabs/puppetlabs-powershell/pull/144) ([Iristyle](https://github.com/Iristyle))
- (maint) Minor PS tweaks in prep for pipe rewrite [#143](https://github.com/puppetlabs/puppetlabs-powershell/pull/143) ([Iristyle](https://github.com/Iristyle))
- (MODULES-3443) Emit better user code exceptions [#139](https://github.com/puppetlabs/puppetlabs-powershell/pull/139) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3588) Update documentation for change in MODULES-3399 [#138](https://github.com/puppetlabs/puppetlabs-powershell/pull/138) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3775) (msync 8d0455c) update travis/appveyer w/Ruby 2.3 [#137](https://github.com/puppetlabs/puppetlabs-powershell/pull/137) ([MosesMendoza](https://github.com/MosesMendoza))
- (MODULES-3709) Respect resource timeout interval in powershell manager [#136](https://github.com/puppetlabs/puppetlabs-powershell/pull/136) ([glennsarti](https://github.com/glennsarti))
- (maint) Fix test failures for Puppet 4.6 [#135](https://github.com/puppetlabs/puppetlabs-powershell/pull/135) ([Iristyle](https://github.com/Iristyle))
- (maint) modulesync 70360747 [#134](https://github.com/puppetlabs/puppetlabs-powershell/pull/134) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3640) Update modulesync 30fc4ab [#132](https://github.com/puppetlabs/puppetlabs-powershell/pull/132) ([MosesMendoza](https://github.com/MosesMendoza))
- (MODULES-3399) Exit user scripts via $LASTEXITCODE  [#129](https://github.com/puppetlabs/puppetlabs-powershell/pull/129) ([Iristyle](https://github.com/Iristyle))
- (MODULES-3565) Change the working directory if specified in the resource  [#125](https://github.com/puppetlabs/puppetlabs-powershell/pull/125) ([glennsarti](https://github.com/glennsarti))

## [2.0.2](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.0.2) - 2016-07-12

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.1...2.0.2)

### Other

- (FM-5344) Prepare for release 2.0.2 [#128](https://github.com/puppetlabs/puppetlabs-powershell/pull/128) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3468) Update README.md [#127](https://github.com/puppetlabs/puppetlabs-powershell/pull/127) ([glennsarti](https://github.com/glennsarti))
- (maint) modulesync 724153ca2 [#126](https://github.com/puppetlabs/puppetlabs-powershell/pull/126) ([glennsarti](https://github.com/glennsarti))
- (maint) modulesync 99efa6139 [#124](https://github.com/puppetlabs/puppetlabs-powershell/pull/124) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3536) modsync update [#122](https://github.com/puppetlabs/puppetlabs-powershell/pull/122) ([glennsarti](https://github.com/glennsarti))
- (MODULES-2634) PowerShell Module doesn't run template with try/catch [#120](https://github.com/puppetlabs/puppetlabs-powershell/pull/120) ([DLuCJ](https://github.com/DLuCJ))
- (MODULES-2634) Fix PS try/catch in puppet 3.X [#119](https://github.com/puppetlabs/puppetlabs-powershell/pull/119) ([jpogran](https://github.com/jpogran))
- (MODULES-2634) Fix tests for non-Windows agents [#118](https://github.com/puppetlabs/puppetlabs-powershell/pull/118) ([Iristyle](https://github.com/Iristyle))
- (MODULES-2634) Remove unnecessary binary test file [#117](https://github.com/puppetlabs/puppetlabs-powershell/pull/117) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3406) Optimize PowerShell parse time [#115](https://github.com/puppetlabs/puppetlabs-powershell/pull/115) ([Iristyle](https://github.com/Iristyle))
- (maint) Remove require_relative for Ruby 1.8.7 [#114](https://github.com/puppetlabs/puppetlabs-powershell/pull/114) ([Iristyle](https://github.com/Iristyle))
- (MODULES-2634) Try / Catch Test Updates [#113](https://github.com/puppetlabs/puppetlabs-powershell/pull/113) ([Iristyle](https://github.com/Iristyle))
- (maint) Fix changelog release dates [#111](https://github.com/puppetlabs/puppetlabs-powershell/pull/111) ([glennsarti](https://github.com/glennsarti))

## [2.0.1](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.0.1) - 2016-05-24

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/2.0.0...2.0.1)

### Other

- (FM-5241) Release Powershell 2.0.1 [#107](https://github.com/puppetlabs/puppetlabs-powershell/pull/107) ([glennsarti](https://github.com/glennsarti))
- (FM-5240) Prevent powershell_manager DSC conflict [#106](https://github.com/puppetlabs/puppetlabs-powershell/pull/106) ([Iristyle](https://github.com/Iristyle))
- (MODULES-2634) Verify try/catch with PowerShell module [#104](https://github.com/puppetlabs/puppetlabs-powershell/pull/104) ([jpogran](https://github.com/jpogran))

## [2.0.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/2.0.0) - 2016-05-18

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.6...2.0.0)

### Other

- Merge branch 'master' into stable [#102](https://github.com/puppetlabs/puppetlabs-powershell/pull/102) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3356) Branding Name Change [#101](https://github.com/puppetlabs/puppetlabs-powershell/pull/101) ([jpogran](https://github.com/jpogran))
- (MODULES-3344) Nano Server Compatibility [#100](https://github.com/puppetlabs/puppetlabs-powershell/pull/100) ([Iristyle](https://github.com/Iristyle))
- (FM-4639) Prepare module for 2.0.0 release [#98](https://github.com/puppetlabs/puppetlabs-powershell/pull/98) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3321) Ensure upgrade warning Windows only [#97](https://github.com/puppetlabs/puppetlabs-powershell/pull/97) ([Iristyle](https://github.com/Iristyle))
- (maint) Update copyright notice with correct authors [#96](https://github.com/puppetlabs/puppetlabs-powershell/pull/96) ([glennsarti](https://github.com/glennsarti))
- Merge stable to master [#95](https://github.com/puppetlabs/puppetlabs-powershell/pull/95) ([ferventcoder](https://github.com/ferventcoder))
- (maint) modsync update - master [#94](https://github.com/puppetlabs/puppetlabs-powershell/pull/94) ([glennsarti](https://github.com/glennsarti))
- (maint) modsync update - stable [#93](https://github.com/puppetlabs/puppetlabs-powershell/pull/93) ([glennsarti](https://github.com/glennsarti))
- {WIP}(FM-4639) Release 2.0.0 [#92](https://github.com/puppetlabs/puppetlabs-powershell/pull/92) ([glennsarti](https://github.com/glennsarti))
- Revert "(MODULES-2634) Test try/catch in PowerShell provider" [#90](https://github.com/puppetlabs/puppetlabs-powershell/pull/90) ([glennsarti](https://github.com/glennsarti))
- (MODULES-3280) Remove Verbose Environment Variable Handling [#87](https://github.com/puppetlabs/puppetlabs-powershell/pull/87) ([jpogran](https://github.com/jpogran))
- (MODULES-3137) Log PowerShell Streams [#86](https://github.com/puppetlabs/puppetlabs-powershell/pull/86) ([jpogran](https://github.com/jpogran))
- (MODULES-2634) Test try/catch in PowerShell provider [#84](https://github.com/puppetlabs/puppetlabs-powershell/pull/84) ([jpogran](https://github.com/jpogran))
- (MODULES-3192) Use file() instead of template() in the README [#83](https://github.com/puppetlabs/puppetlabs-powershell/pull/83) ([natemccurdy](https://github.com/natemccurdy))
- (maint) Fix private FFI declarations [#82](https://github.com/puppetlabs/puppetlabs-powershell/pull/82) ([Iristyle](https://github.com/Iristyle))
- (FM-4952) Restrict Rake to ~> 10.1 [#81](https://github.com/puppetlabs/puppetlabs-powershell/pull/81) ([ferventcoder](https://github.com/ferventcoder))
- (maint) Changed allowed rspec version [#79](https://github.com/puppetlabs/puppetlabs-powershell/pull/79) ([Iristyle](https://github.com/Iristyle))
- (MODULES-2962) Reuse PowerShell Session [#78](https://github.com/puppetlabs/puppetlabs-powershell/pull/78) ([Iristyle](https://github.com/Iristyle))
- (FM-4881) Remove gem install bundler on Appveyor [#76](https://github.com/puppetlabs/puppetlabs-powershell/pull/76) ([jpogran](https://github.com/jpogran))
- (MODULES-3011) Acceptance Test for Single Session [#75](https://github.com/puppetlabs/puppetlabs-powershell/pull/75) ([cowofevil](https://github.com/cowofevil))
- Mention that templates need to have DOS linefeeds [#73](https://github.com/puppetlabs/puppetlabs-powershell/pull/73) ([mattock](https://github.com/mattock))
- (maint) update modsync / fix build [#71](https://github.com/puppetlabs/puppetlabs-powershell/pull/71) ([ferventcoder](https://github.com/ferventcoder))
- (maint) update modulesync files [#68](https://github.com/puppetlabs/puppetlabs-powershell/pull/68) ([ferventcoder](https://github.com/ferventcoder))

## [1.0.6](https://github.com/puppetlabs/puppetlabs-powershell/tree/1.0.6) - 2015-12-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.5...1.0.6)

### Other

- (FM-3477) Release 1.0.6 [#69](https://github.com/puppetlabs/puppetlabs-powershell/pull/69) ([ferventcoder](https://github.com/ferventcoder))
- (MODULES-2452) Update Beaker Version [#66](https://github.com/puppetlabs/puppetlabs-powershell/pull/66) ([ferventcoder](https://github.com/ferventcoder))
- (MODULES-2443) Ensure Facter version for old Puppets [#65](https://github.com/puppetlabs/puppetlabs-powershell/pull/65) ([ferventcoder](https://github.com/ferventcoder))

## [1.0.5](https://github.com/puppetlabs/puppetlabs-powershell/tree/1.0.5) - 2015-07-29

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.4...1.0.5)

### Other

- (FM-3079) Release 1.0.5 - PE 2015.2.0 update [#64](https://github.com/puppetlabs/puppetlabs-powershell/pull/64) ([cyberious](https://github.com/cyberious))
- (maint) puppetlabs_spec_helper ~>0.10.3 [#63](https://github.com/puppetlabs/puppetlabs-powershell/pull/63) ([ferventcoder](https://github.com/ferventcoder))
- (MODULES-2207) bin beaker-rspec to ~> 5.1 [#62](https://github.com/puppetlabs/puppetlabs-powershell/pull/62) ([ferventcoder](https://github.com/ferventcoder))
- (MODULES-2207) Add Beaker-Rspec [#61](https://github.com/puppetlabs/puppetlabs-powershell/pull/61) ([ferventcoder](https://github.com/ferventcoder))
- (MODULES-2207) Update Modulesync [#60](https://github.com/puppetlabs/puppetlabs-powershell/pull/60) ([ferventcoder](https://github.com/ferventcoder))
- (maint) Add FUTURE_PARSER back into spec_helper_acceptance [#59](https://github.com/puppetlabs/puppetlabs-powershell/pull/59) ([cyberious](https://github.com/cyberious))
- (maint) Add beaker-puppet_install_helper and remove old code - Allows us to move forward with AIO testing and unified installer [#58](https://github.com/puppetlabs/puppetlabs-powershell/pull/58) ([cyberious](https://github.com/cyberious))
- (maint) Update beaker-rspec to 5.0+ [#56](https://github.com/puppetlabs/puppetlabs-powershell/pull/56) ([Iristyle](https://github.com/Iristyle))
- (maint) Remove step call which was removed from Beaker - Beaker made a breaking change that we now need to remove step calls [#55](https://github.com/puppetlabs/puppetlabs-powershell/pull/55) ([cyberious](https://github.com/cyberious))
- (FM-2752) Add modulesync config and puppet 4 as allowed failure [#54](https://github.com/puppetlabs/puppetlabs-powershell/pull/54) ([cyberious](https://github.com/cyberious))
- Edits to grammar, markdown, and format to match current styleguide. [#50](https://github.com/puppetlabs/puppetlabs-powershell/pull/50) ([jtappa](https://github.com/jtappa))
- (BKR-147) add Gemfile setting for BEAKER_VERSION for puppet... [#49](https://github.com/puppetlabs/puppetlabs-powershell/pull/49) ([anodelman](https://github.com/anodelman))
- Pin Beaker-rspec to 4.x until fixed [#47](https://github.com/puppetlabs/puppetlabs-powershell/pull/47) ([cyberious](https://github.com/cyberious))
- FM-1523: added module summary to metadata.json [#45](https://github.com/puppetlabs/puppetlabs-powershell/pull/45) ([jbondpdx](https://github.com/jbondpdx))
- (maint) Allow setting gem mirror via GEM_SOURCE env var [#44](https://github.com/puppetlabs/puppetlabs-powershell/pull/44) ([justinstoller](https://github.com/justinstoller))
- merge 1.0.x into master [#43](https://github.com/puppetlabs/puppetlabs-powershell/pull/43) ([underscorgan](https://github.com/underscorgan))

## [1.0.4](https://github.com/puppetlabs/puppetlabs-powershell/tree/1.0.4) - 2014-11-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.3...1.0.4)

### Other

- 1.0.4 prep [#42](https://github.com/puppetlabs/puppetlabs-powershell/pull/42) ([underscorgan](https://github.com/underscorgan))
- 1.0.4 Changelog update [#41](https://github.com/puppetlabs/puppetlabs-powershell/pull/41) ([cyberious](https://github.com/cyberious))
- FM-1519 Add future parser testing support [#40](https://github.com/puppetlabs/puppetlabs-powershell/pull/40) ([cyberious](https://github.com/cyberious))
- Update issues url in metadata.json and Add license file [#38](https://github.com/puppetlabs/puppetlabs-powershell/pull/38) ([cyberious](https://github.com/cyberious))

## [1.0.3](https://github.com/puppetlabs/puppetlabs-powershell/tree/1.0.3) - 2014-08-27

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.2...1.0.3)

### Other

- Forgot to move this line too [#37](https://github.com/puppetlabs/puppetlabs-powershell/pull/37) ([hunner](https://github.com/hunner))
- Missed some more default hosts [#36](https://github.com/puppetlabs/puppetlabs-powershell/pull/36) ([hunner](https://github.com/hunner))
- Bugfix for #34 [#35](https://github.com/puppetlabs/puppetlabs-powershell/pull/35) ([hunner](https://github.com/hunner))
- Tests need to install module for PE also [#34](https://github.com/puppetlabs/puppetlabs-powershell/pull/34) ([hunner](https://github.com/hunner))
- Release 1.0.3 [#33](https://github.com/puppetlabs/puppetlabs-powershell/pull/33) ([hunner](https://github.com/hunner))
- Foss testing refactor [#32](https://github.com/puppetlabs/puppetlabs-powershell/pull/32) ([cyberious](https://github.com/cyberious))

## [1.0.2](https://github.com/puppetlabs/puppetlabs-powershell/tree/1.0.2) - 2014-07-16

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.1...1.0.2)

### Other

- 1.0.x [#31](https://github.com/puppetlabs/puppetlabs-powershell/pull/31) ([cyberious](https://github.com/cyberious))
- Prepare 1.0.2 release. [#30](https://github.com/puppetlabs/puppetlabs-powershell/pull/30) ([apenney](https://github.com/apenney))

## [1.0.1](https://github.com/puppetlabs/puppetlabs-powershell/tree/1.0.1) - 2014-07-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/1.0.0...1.0.1)

### Other

- Update metadata.json as it does not implicitly assume that 3.2.3 is not > 3.2.0 [#29](https://github.com/puppetlabs/puppetlabs-powershell/pull/29) ([cyberious](https://github.com/cyberious))

## [1.0.0](https://github.com/puppetlabs/puppetlabs-powershell/tree/1.0.0) - 2014-07-08

[Full Changelog](https://github.com/puppetlabs/puppetlabs-powershell/compare/5b20faca7410a193cd14a70d5d3f7bfa41d6d0e1...1.0.0)
