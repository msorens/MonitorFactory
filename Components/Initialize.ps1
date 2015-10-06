# Copyright (c) 2014-2015 Michael Sorens
# https://github.com/msorens/MonitorFactory

Set-StrictMode -Version Latest

function GenerateCaptions([string]$suppliedDisplayName)
{
	$baseCmdText = $ScriptBlock.ToString().Trim()

	$titleBarText =
		if ($suppliedDisplayName -eq '')
		{ $baseCmdText } # title bar auto-trims and adds "..."
		else { $suppliedDisplayName }

	# for tooltip, add line breaks between commands if lengthy
	$toolTipText =
		if ($baseCmdText.Length -gt $Default.LengthLimitToolTip)
		{ $baseCmdText -replace '(;|\|)',('$1'+"`r`n") }
		else { $baseCmdText }

	# Suppress module loading commands on status bar for brevity
	$statusBarText = 
		if ($baseCmdText.Length -gt $Default.LengthLimitStatusBar)
		{
			$trimText = $baseCmdText -replace '\s*(Import-Module|Add-PSSnapin)[^;]+;\s*',''
			if ($trimText.Length -gt $Default.LengthLimitStatusBar) # still too long?
			{ $trimText.Substring(0,$Default.LengthLimitStatusBar-3) + '...'}
			else { $trimText }
		}
		else { $baseCmdText }

	return @{
		TitleBarText = $titleBarText
		ToolTipText = $toolTipText 
		StatusBarText = $statusBarText 
	}
}

# Convert interval with units to a pure number of seconds,
# and determine display strings relating to it.
function NormalizeInterval([string]$suppliedInterval)
{
	$hour_label = 'hours'
	$minute_label = 'minutes'
	$second_label = 'seconds'
	$validUnits = "'$second_label', '$minute_label', or '$hour_label'"

	$intervalValue = 
		switch -regex ($suppliedInterval) {
			'^\d+$' {
				[int]$suppliedInterval
				break
			}
			'^(?<number>\d+)\s*(?<unit>\w+)$' {
				$re, $number = "^$($matches.unit)", $matches.number
				$multiplier = if ($hour_label -match $re) { 3600 }
				elseif ($minute_label -match $re) { 60 }
				elseif ($second_label -match $re) { 1 }
				else {
					throw "Invalid unit [$($matches.unit)]: must be $validUnits"
				};
				[int]$number * $multiplier
				break
			}
			default {
				throw "Invalid interval [$suppliedInterval]: must be an integer optionally followed by $validUnits"
			}
	}

	$displayIntervalValue, $displayIntervalUnits = 
		if ($intervalValue -le $Default.CutOffSecondsToShowSeconds) { $intervalValue, $second_label }
		elseif ($intervalValue -le $Default.CutOffSecondsToShowMinutes) { ($intervalValue / 60), $minute_label }
		else { ($intervalValue / 3600), $hour_label }

	$intervalFormatString = 
		if ([int]$displayIntervalValue -eq $displayIntervalValue) 
		{ ' Interval: {0} {1} ' }
		else { ' Interval: {0:N1} {1} '}

	return @{
		IntervalValue = $intervalValue
		DisplayIntervalValue = $displayIntervalValue
		DisplayIntervalUnits = $displayIntervalUnits
		IntervalFormatString = $intervalFormatString
	}
}

