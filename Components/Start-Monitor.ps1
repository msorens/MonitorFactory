# Copyright (c) 2014-2015 Michael Sorens
# https://github.com/msorens/MonitorFactory

#requires -Version 3
Set-StrictMode -Version Latest

<#

.SYNOPSIS
Runs a sequence of PowerShell commands at regular intervals,
displaying the results in an interactive grid. 

.DESCRIPTION
Start-Monitor provides a framework for displaying frequently changing data.
Some examples:
  * current processes on your computer
  * files in a directory tree
  * files that are newer in source control compared to your working set

Before invoking Start-Monitor, formulate a "recipe" in the form of a
PowerShell script block.  As PowerShell's own help illustrates
(see about_script_blocks in PowerShell help), you can run Invoke-Command
to execute a script block, as in:

    Invoke-Command -ScriptBlock { Get-Process }

... which is exactly the same as if you had just invoked "Get-Process"
by itself, producing a list of processes on your computer.
Start-Monitor is very similar but with two crucial differences.
This again invokes "Get-Process"...

    Start-Monitor -ScriptBlock { Get-Process }

but (a) sends the output to an interactive grid and (b) repeats ad infinitum
at an interval of your choice.

CONSIDERATIONS FOR SCRIPT BLOCKS

== Be Aware of Multiple Object Types ==

Unlike Invoke-Command, which just outputs to the console, there are
some considerations to be aware of when constructing your script block.
Let's switch to Get-ChildItem to illustrate these.

    Start-Monitor -ScriptBlock { Get-ChildItem -Recurse }

This monitors all files and directories rooted at the current directory,
flattening the result into single list of objects.  But what kind of objects?
Get-ChildItem emits both FileInfo and DirectoryInfo objects,
each with different properties.
The interactive grid that is generated, however, can only handle a single
object type; it determines its columns from the first object it encounters.
For Get-ChildItem this will typically be a DirectoryInfo object
so all the column headers will correspond to its properties.
FileInfo objects share a lot of the same properties, but not all;
files will thus have some columns shown as empty and some file properties
will not appear at all.

Adding a filter to restrict the output to ignore directories...

	Start-Monitor { Get-Child -File -Recurse }

... will allow you to see all the properties of each file,
because all objects going into the grid are the same type, FileInfo.


== Be Aware of the Properties of Your Output ==

You will immediately notice that the grid display is quite different from
what you get on the console when you just run Get-ChildItem.
I'm not speaking just of the formatting. Rather, you will see a lot more data:
the grid has around 20 columns whereas on the console you only see four
(Mode, LastWriteTime, Length, and Name) !

This difference is due to the fact that PowerShell defines a set of
default properties for a cmdlet that it uses when it outputs to the console.
But that is merely an output rendering artifact. All the properties of the 
object are really there. And they have to be: otherwise, it would not make
any sense that when you pipe to another cmdlet you would only get a portion
of an object! So for Start-Monitor, your script block's output does not
go to the console. Rather it is consumed by an internal function that
constructs a DataTable object that in turn is connected to the grid view
to render it as output. But the constructor function sees the entire object;
in the case of Get-ChildItem, that means all of its 20 or so properties.
Therefore, if you want to get the same output that you would on the console,
you have to explicitly select just those properties:

	Start-Monitor { ls -File -R | select Name,Mode,LastWriteTime,Length }


== Foreground and Background Execution ==

Start-Monitor can be run as a foreground or background process.
The only practical difference is that--though either flavor will pop open
a secondary window--the synchronous version runs in the foreground, locking up
your original PowerShell console, while the asynchronous version runs in the
background, and allows you to continue using your original PowerShell window
as well. Just add -AsJob to run as a background process.
Internally, there are a lot more machinations needed to support the
asynchronous version. But the only relevant note here is
that each invocation generates a background job that persists for the 
duration of your PowerShell session--even if you close the monitor window!
Get-Job will list your jobs. If you are not getting expected output,
you can use Receive-Job to see if any errors have been output because
inside a job container such messages no longer appear on your console.
Since you are essentially writing a PowerShell program and passing that 
to Start-Monitor it is quite possible for something to go awry.
So it is often a good idea to run your code without -AsJob first,
because any errors or messages show up directly on the console.


== Using Variables ==

The samples you have seen thus far use script blocks whose contents are static,
	i.e. they are akin to literals rather than variables. What if you wanted
to make a convenience wrapper to monitor the contents of a directory you
specify at runtime? Consider first the synchronous (foreground) version:

function MonitorDir($myDir)
{
	Start-Monitor { ls $myDir -R }
}

That will work fine; the $myDir variable is accessible because the script block
is not wrapped inside a background job. As soon as you change it to a background job, though...

function MonitorDir($myDir)
{
	Start-Monitor { ls $myDir -R } -AsJob
}

... you will get an empty grid. If you then query the data from the job
("Receive-Job *" is an easy way to not bother with the ID if you only have
 one outstanding job) you will see an error saying the variable has not been set.
To get around this issue you have to "manually" supply any arguments you
wish to inject into the script block using the $ArgumentList parameter:

function MonitorDir($myDir)
{
	Start-Monitor { ls $args[0] -R } -AsJob -ArgumentList $myDir
}

The -ArgumentList is, as it intimates by the name, a list, though here
it is just passing a single value.
Index into the list as shown above ($args[x]) to retrieve the supplied values.


== Using Modules ==

When you need to use an external module within your script block
you must explictly bring it in scope inside the script block;
it will not be inherited from your current scope. Depending on the module
this will require an Add-PSSnapin call or an Import-Module call.
These Add-PSSnapin and Import-Module statements must be the first code
in your script block. If you think you may be having an issue of your imports
not actually being imported--especially when running as a background job--use
the -Verbose parameter; it will identify where it thinks the separation
between your imports and the rest of your code lies.


== Operation Notes ==

* The ScriptBlock parameter is displayed in the window's title bar
(truncated to fit if too long) unless you specify a more user-friendly name
with the DisplayName parameter.

* The ScriptBlock parameter is also displayed in the bottom status bar,
again truncated to fit. Also, since space there is limited, any leading
Import-Module or Add-PSSnapin commands are suppressed.
If you hover over the value in the status bar, however, you can see the entire
ScriptBlock in a tooltip. If it is a lengthy command, then line-breaks
are added to the tooltip to help ensure it is all visible at one time.

* Besides the regular refresh interval, you can refresh on-demand from
the menu or Ctrl+R. Note that that does *not* alter the next auto-refresh time.

* If the time-to-refresh is less than a minute, the countdown timer on the
status bar refreshes every second.  Otherwise, it refreshes every 5 seconds.

* If you get a blank grid or otherwise unexpected output, check the job details
for possible errors. (Look up the last job id with Get-Job or,
if you do not have other active jobs you can just do "Receive-Job *" to
get the output of all jobs.)
Alternately, rerun Start-Monitor without the -AsJob parameter
to show any errors or message directly in the console.

* You can copy text (Ctrl+C) from the data grid but only when you run in
the foreground. Attempts to copy inside a background grid
(initiated by Start-Monitor -AsJob...) will generate a pop-up error.

.PARAMETER ScriptBlock
Sequence of commands to execute.
You may specify a single command, a command pipeline, or multiple commands.
(If you are entering all on one line, separate multiple commands with semicolons.) 
Be sure to include Import-Module and Add-PSSnapin commands as needed to find
your commands!
Default: { Get-Process | Select-Object PSResources,cpu }

.PARAMETER Interval
The time between successive data refreshes.  This can either be
a simple integer or an integer with units of 'hours', 'minutes', or 'seconds',
or abbreviations thereof. Note that no spaces are allowed between the number
and the units, so any of these are valid: 10, 10min, 10h, 10seconds.
Default unit: seconds
Default value: 10

.PARAMETER DisplayName
An optional string to display in the window title bar rather than
the raw command sequence.

.PARAMETER ArgumentList
Specifies the arguments (parameter values) for the script that is specified
by the ScriptBlock parameter.

.PARAMETER AsJob
Runs the monitor as a background task, freeing up your PowerShell host
to receive other inputs from you.

.EXAMPLE
Start-Monitor { ls -recurse }
Monitor all files and directories rooted at the current directory.
Note that some cmdlets return more than one type of object.
Get-ChildItem (alias ls used here) emits both FileInfo and DirectoryInfo objects.
The interactive form that is generated, however, determines the columns
from the first object it encounters. Typically this will be a DirectoryInfo
object so all the column headers will correspond to its properties.
FileInfo objects share a lot of the same properties, but not all;
files will thus have some columns shown as empty and some properties
will not appear at all.

.EXAMPLE
Start-Monitor { ls -File -recurse } 
Same as above, except limit the data to just objects that are files.
Here you will then see all the properites of files.

.EXAMPLE
Start-Monitor { ls -File -recurse | select Name,Mode,LastWriteTime,Length }
The last example showed *all* the properties of files, many more than
Get-ChildItem normally shows on the console. This example shows that you can
explicitly specify just the properties you want to appear.

.EXAMPLE
Start-Monitor { ls -File -r | select Name,Mode,LastWriteTime,Length,@{n='Lines';e={ cat $_ | measure -line | select -exp Lines }} }
Same as above but with an additional computed property, the number of non-empty lines in each file.

.NOTES
Adapted from this URL which no longer exists:
http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx

Archived URL on the WayBack Machine:
https://web.archive.org/web/20071013045241/http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx

Also found it here:
https://code.google.com/p/mod-posh/source/browse/powershell/playground/Start-Monitor.ps1?r=409

#>

function Start-Monitor
{
	[CmdletBinding()]
	param(
		[ScriptBlock]$ScriptBlock = $DefaultScriptBlock,
		[string]$Interval = '10',
		[string]$DisplayName = '',
		[object[]]$ArgumentList = @(),
		[switch]$AsJob
	)

	if (!$AsJob) {
		Start-MonitorSync @PsBoundParameters
		return
	}

	# Return value not used here; this just gives immediate feedback to
	# the user in the event of an incorrectly specified value.
	$null = NormalizeInterval $Interval

	$myModule = (Get-Command Start-Monitor).Module.Path  -replace '\.psm1$','.psd1'
	$job = Start-Job {
		$dir,$module,$argList = $args
		Set-Location $dir # stay in current directory
		Import-Module $module # import myself *within* the job

		# Separate leading imports from the remainder of a script block.
		function SplitConcerns([string]$ScriptBlockText)
		{
			$regex = '\A\s*((?:\s*(?:Import-Module|Add-PSSnapin).*?(?:;|$))+)(.*)'
			$opt = [System.Text.RegularExpressions.RegexOptions]
			$options = $opt::MultiLine -bor $opt::SingleLine -bor $opt::IgnoreCase
			$match = [regex]::Match($ScriptBlockText, $regex, $options)
			$result = if ($match.Success) { $match.Groups[1].Value, $match.Groups[2].Value }
			else { $null, $ScriptBlockText }
			return $result
		}

		$scriptBlockText = $using:ScriptBlock # '$using' converts to string!
		$imports, $scriptBlockText = SplitConcerns $scriptBlockText
		# Inside here $VP is an int not a string!
		if ($using:VerbosePreference -gt 0) { 
			# job output that does *not* impact what is fed to the grid vew.
			Write-Host "verbose = $using:VerbosePreference"
			Write-Host "imports = [$imports]"
			Write-Host "scriptBlockText = [$scriptBlockText]"
		}
		$params = @{
			DisplayName = $using:DisplayName
			Interval = $using:Interval
			ScriptBlock = [ScriptBlock]::Create($scriptBlockText);
			ArgumentList = $argList
		}
		# Determined by experiment that had to pull out imports here;
		# leaving them in the original script block they just silently failed
		# for the case of "Add-PSSnapin Microsoft.TeamFoundation.PowerShell;".
		# Note that it works fine in synchronous mode.
		if ($imports) { Invoke-Expression $imports }
		# As iex is "evil", this will also work...but is it just as evil?
		# if ($imports) { Invoke-Command -ScriptBlock ([ScriptBlock]::Create($imports)) }

		$global:asyncMode = $true
		Start-MonitorSync @params
	} -ArgumentList $pwd,$myModule,$ArgumentList

	# "Write-Verbose $job" would not expand the variable!
	if ($VerbosePreference -ne 'SilentlyContinue') { $job }
}

<#

.SYNOPSIS
The synchronous runner for Start-Monitor.

.DESCRIPTION
This needs to be exposed in the API for things to work properly
but you never need to run it directly. See Start-Monitor.

.PARAMETER ScriptBlock
Sequence of commands to execute.
You may specify a single command, a command pipeline, or multiple commands.
Multiple commands must be separated with semicolons since you must enter
them all on a single line.
Be sure to include Import-Module and Add-PSSnapin commands as needed to find
your commands!
Default: { Get-Process | Select-Object PSResources,cpu }

.PARAMETER Interval
The time between successive runs. This can either be a simple integer or
an integer with units of 'hours', 'minutes', or 'seconds',
or abbreviations thereof. Note that no spaces are allowed between the number
and the units, so any of these are valid: 10, 10min, 10h, 10seconds.
Default unit: seconds
Default value: 10

.PARAMETER DisplayName
An optional string to display in the window title bar rather than
the raw command sequence.

.PARAMETER ArgumentList
Specifies the arguments (parameter values) for the script that is specified
by the ScriptBlock parameter.

#>

function Start-MonitorSync
{
	[CmdletBinding()]
	param(
		[ScriptBlock]$ScriptBlock = $DefaultScriptBlock,
		[string]$Interval = '10',
		[string]$DisplayName = '',
		[object[]]$ArgumentList = @()
	)

	$intervalItems = NormalizeInterval $Interval
	$captionItems = GenerateCaptions $DisplayName
	$formItems = GenerateForm $captionItems $EventHandlers
	$timerItems = GenerateTimer $EventHandlers
	$dynamicItems = @{
		SecsToInterval = $intervalItems.IntervalValue
		LastRowCount = -1
		PriorData = $null
		CurrentData = $null
	}
	$trackerItems = $formItems + $intervalItems + $timerItems + $dynamicItems
	$script:tracker = [PsCustomObject]$trackerItems

	UpdateTimerInterval
	$tracker.Timer.Enabled = $true
	$tracker.Form.ShowDialog()
}


$global:asyncMode = $false

$EventHandlers = @{
	OnShown = {
		UpdateDataTableAndHighlightAction
		$tracker.TimingIntervalLabel.Text = GetIntervalText
		$tracker.Form.Activate()
	}
	OnFormClosing = {
		$tracker.Timer.Dispose() # without this, timer behaves erratically next time!
	}
	OnClickPause = {
		$tracker.Timer.Enabled = !$tracker.Timer.Enabled
		$tracker.TimingClockLabel.BackColor =
			if ($tracker.Timer.Enabled) {$Default.NeutralColor} else { $Default.PauseColor }
	}
	OnClickRefresh = {
		UpdateDataTableAndHighlightAction $Default.RefreshHighlightManualColor
	}
	OnClickCopy = {
		# Unfortunately Clipboard.SetDataObject requires STA mode and a background job is not!
		# If not for this interception of Ctrl+C, would not need any code to support a copy;
		# the grid already supports it.
		if ($asyncMode) {
			PopupMessage 'Cannot Copy' 'Copy is disabled in background mode--re-run without -AsJob'
		}
		else {
			CopyToClipboard $tracker.Grid
		}
	}
	OnClickExportCsv = {
		$name = GetFileName $pwd
		if ($name) {
			$tracker.Grid.DataSource | Export-Csv $name -NoTypeInformation
		}
	}
	OnClickQuit = {
		$tracker.Form.close()
	}
	OnClickSwapData = {
		if ($tracker.PriorDataMenuItem.Checked) {
			$table = $tracker.PriorData
			$tracker.RowCountLabel.BackColor = $Default.HistoricalDataColor
		} else {
			$table = $tracker.CurrentData
			$tracker.RowCountLabel.BackColor = $Default.NeutralColor
		}
		UpdateDataGrid $table
	}
	OnTick = {
		$tracker.SecsToInterval -= ($tracker.Timer.Interval / 1000)
		if ($tracker.SecsToInterval -le 0 ) {
			$tracker.SecsToInterval = $tracker.IntervalValue
			UpdateDataTableAndHighlightAction 
		}
		UpdateTimerInterval
		$tracker.TimingClockLabel.Text = GetClockText
		$tracker.StatusStrip.Update()
	}
}

function UpdateTimerInterval()
{
	$newInterval = if ($tracker.SecsToInterval -gt $Default.LongShortDividerSeconds )
	{ $Default.RefreshMillisecondsLong } Else { $Default.RefreshMillisecondsShort }
	if ($newInterval -ne $tracker.Timer.Interval) { $tracker.Timer.Interval = $newInterval }
}

function GetIntervalText()
{
	return $tracker.IntervalFormatString -f
		$tracker.DisplayIntervalValue, $tracker.DisplayIntervalUnits
}

function GetClockText()
{
	return new-Timespan -sec $tracker.SecsToInterval
}

function UpdateDataTableAndHighlightAction([string]$color = $Default.RefreshHighlightAutoColor)
{
	$tracker.CommandLabel.BackColor = $color
	$tracker.StatusStrip.Update()
	$table = Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList | OutDataTable
	UpdateDataGrid $table
	$tracker.CommandLabel.BackColor = $Default.NeutralColor

	# reset after possibly showing prior data
	$tracker.PriorDataMenuItem.Checked = $false
	$tracker.RowCountLabel.BackColor = $Default.NeutralColor

	if ($tracker.PriorData -ne $null) { $tracker.PriorData.Dispose() }
	$tracker.PriorData = $tracker.CurrentData
	$tracker.CurrentData = $table
	$tracker.PriorDataMenuItem.Enabled = $tracker.PriorData -ne $null

	NotifyIfChanged
	$tracker.LastRowCount = $table.Rows.count
}

function UpdateDataGrid([System.Data.DataTable]$table)
{
	$col = $tracker.Grid.SortedColumn
	$sortOrder = $tracker.Grid.SortOrder.ToString()
	$tracker.Grid.DataSource = $table.psObject.baseobject
	if ($sortOrder -ne 'None' ) {
		$tracker.Grid.Sort($tracker.Grid.columns[($col.name)], $SortOrder)
	}
	$tracker.RowCountLabel.Text = ' Rows : {0} ' -f $table.Rows.count

	$tracker.Grid.AutoResizeColumns()
	$tracker.Grid.Columns | % {
		if ($_.Width -gt $Default.MaxColumnWidth)
		{
			$_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::None
			$_.Width = $Default.MaxColumnWidth
			$tracker.Grid.Update()
		}
	}
}

function NotifyIfChanged()
{
	# Rough but quick measure that something has changed
	if ($tracker.LastRowCount -ne $table.Rows.count) {
		Get-Process -Id $PID | Invoke-FlashWindow
	}
}

Export-ModuleMember Start-Monitor
# Don't want this to be exposed but it is a necessity so it can
# be found by the async (AsJob) code.
Export-ModuleMember Start-MonitorSync

