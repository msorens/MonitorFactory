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
Also see some practical examples and detailed notes on how to use it
on Simple-Talk.com: [Build Your Own Resource Monitor in a Jiffy](https://www.simple-talk.com/sysadmin/powershell/build-your-own-resource-monitor-in-a-jiffy/)

Here's a sample of what the output looks like:
![MonitorFactory sample with callouts](https://cloud.githubusercontent.com/assets/6817500/9609285/c510f2d2-5087-11e5-934c-53ad9054b167.jpg)

Wrappers
----------
It is often convenient to create a wrapper for a monitor or set of monitors
that you want to revisit frequently. Then, instead of having to type all this...

```
Start-Monitor { 
    Invoke-Sqlcmd -InputFile TopTwentyQueries.sql -Server localhost -Database master
} -AsJob -Interval 5sec -DisplayName 'Longest Running Queries'
```
you could use the much more compact

```
Start-SqlMonitor TopTwentyQueries.sql localhost master 'Longest Running Queries'
```

The distribution includes a Wrappers folder that contains Start-SqlMonitor and others--please contribute yours if you come up with something useful!

