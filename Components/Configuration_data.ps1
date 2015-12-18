# Copyright (c) 2014-2015 Michael Sorens
# https://github.com/msorens/MonitorFactory

Set-StrictMode -Version Latest

[ScriptBlock]$DefaultScriptBlock = {
	Get-Process | Select-Object PSResources,cpu
}

$Default = @{
	RefreshMillisecondsLong     = 5000
	RefreshMillisecondsShort    = 1000
	LongShortDividerSeconds     = 60

	CutOffSecondsToShowSeconds  = 90
	CutOffSecondsToShowMinutes  = 90 * 60

	RefreshHighlightAutoColor   = 'Red'
	RefreshHighlightManualColor = 'LightBlue'
	HistoricalDataColor         = 'Yellow'
	PauseColor                  = 'LightSalmon'
	NeutralColor                = 'Control'

	LengthLimitStatusBar        = 80
	LengthLimitToolTip          = 80

	GridViewWidth               = 810
	GridViewLength              = 410
	MaxColumnWidth              = 400

	WindowTitlePrefix           = 'PSMonitor'
}

