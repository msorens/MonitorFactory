Set-StrictMode -Version Latest

function GenerateCaptions()
{
	$baseCmdText = $ScriptBlock.ToString().Trim()

	$titleBarText =
		if ($DisplayName -eq '')
		{ $baseCmdText } # title bar auto-trims and adds "..."
		else { $DisplayName }

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

# Convert $Interval with units to a pure number of seconds,
# and determine display strings relating to it.
function NormalizeInterval()
{
	$intervalValue = 
		switch -regex ($Interval) {
			'^\d+$' {
				[int]$Interval
				break
			}
			'^(?<number>\d+)(?<unit>\w+)$' {
				$re, $number = "^$($matches.unit)", $matches.number
				$multiplier = if ('hours' -match $re) { 3600 }
				elseif ('minutes' -match $re) { 60 }
				elseif ('seconds' -match $re) { 1 }
				else {
					throw "Invalid unit [$($matches.unit)]: must be 'seconds', 'minutes', or 'hours'"
				};
				[int]$number * $multiplier
				break
			}
			default {
				throw "Invalid interval [$Interval)]: must be an integer optional followed by 'seconds', 'minutes', or 'hours'"
			}
	}

	$displayIntervalValue, $displayIntervalUnits = 
		if ($intervalValue -le $Default.CutOffSecondsToShowSeconds) { $intervalValue, 'seconds'}
		elseif ($intervalValue -le $Default.CutOffSecondsToShowMinutes) { ($intervalValue / 60), 'minutes' }
		else { ($intervalValue / 3600), 'hours' }

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

