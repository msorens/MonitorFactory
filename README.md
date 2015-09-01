MonitorFactory
=======

Monitor Factory is a small and lightweight PowerShell utility that generates near-real-time monitors
for any data resources you like. All you need do is
* figure out how to collect what you want in PowerShell (and PowerShell is rich enough and expressive enough to allow you to grab data about most anything on your computer), and then
* feed that code as a script block to Monitor Factory to generate a monitor for continual update and display.


Installation
----------
1. Unzip MonitorFactory-master.zip into your PowerShell Modules directory ($env:UserProfile\Documents\WindowsPowerShell\Modules) and drop the "-master" suffix on the extracted folder.
2. Import the module in your profile or import it manually: `Import-Module MonitorFactory`

Usage
----------
See extensive help available from the cmdlet itself: `Get-Help Start-Monitor`

_More notes coming soon!_
