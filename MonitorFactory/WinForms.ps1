Set-StrictMode -Version Latest

Add-Type -AssemblyName 'System.Windows.Forms'

# Radio Button handler example:
#	$LocalEventHandlers = @{
#		OnClickSetSelectMode = {
#			$sender = $args[0]
#			$sender.Owner.Items | % { $_.Checked = ($_ -eq $sender) }
#			foreach ($item in $sender.Owner.Items)
#			{
#				$item.Checked = ($item -eq $sender)
#				if ($item.Checked) { SetSelectionMode $item.Text }
#			}
#		}
#	}

function GenerateForm([hashtable]$captionItems, [hashtable]$eventHandlers)
{
	################ Form

	$form = New-Object System.Windows.Forms.Form
	$form.text = '{0}: {1}' -f $Default.WindowTitlePrefix, $captionItems.TitleBarText
	$form.Size =  New-Object System.Drawing.Size($Default.GridViewWidth,$Default.GridViewLength)
	$form.Add_Shown($eventHandlers.OnShown)
	$form.Add_FormClosing($eventHandlers.OnFormClosing)
	
	################ DataGrid
	
	$grid = New-Object System.Windows.Forms.DataGridView
	$grid.Dock = [System.Windows.Forms.DockStyle]::Fill
	$grid.ColumnHeadersHeightSizeMode = 
		[System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
	$grid.SelectionMode = 'RowHeaderSelect'
	$grid.AllowUserToAddRows = $false
	$grid.AllowUserToOrderColumns = $true
	$grid.RowHeadersWidth = 12
	$grid.ReadOnly = $true
	$grid.ClipboardCopyMode = [System.Windows.Forms.DataGridViewClipboardCopyMode]::EnableAlwaysIncludeHeaderText
	$form.Controls.Add($grid)
	
	################ Menu
	$keys = [System.Windows.Forms.Keys]
	$menuStrip = New-Object System.Windows.Forms.MenuStrip
	$form.Controls.Add($menuStrip)

	$menu = New-Object System.Windows.Forms.ToolStripMenuItem('&File')
	[void]$menuStrip.Items.Add($menu)
	
	$menuItem = New-Object System.Windows.Forms.ToolStripMenuItem('&Export to CSV')
	$menuItem.ShortcutKeys = $keys::Control -bor $keys::E
	$menuItem.Add_Click($eventHandlers.OnClickExportCsv)
	[void]$menu.DropDownItems.Add($menuItem)
	
	$menuItem = New-Object System.Windows.Forms.ToolStripMenuItem('E&xit')
	$menuItem.ShortcutKeys = $keys::Alt -bor $keys::F4
	$menuItem.Add_Click($eventHandlers.OnClickQuit)
	[void]$menu.DropDownItems.Add($menuItem)
	
	$menu = New-Object System.Windows.Forms.ToolStripMenuItem('&Action')
	[void]$menuStrip.Items.Add($menu)
	
	$menuItem = New-Object System.Windows.Forms.ToolStripMenuItem('&Copy')
	$menuItem.ShortcutKeys = $keys::Control -bor $keys::C
	$menuItem.Add_Click($eventHandlers.OnClickCopy)
	[void]$menu.DropDownItems.Add($menuItem)
	
	$menuItem = New-Object System.Windows.Forms.ToolStripMenuItem('&Refresh')
	$menuItem.ShortcutKeys = $keys::Control -bor $keys::R
	$menuItem.Add_Click($eventHandlers.OnClickRefresh)
	[void]$menu.DropDownItems.Add($menuItem)
	
	$menuItem = New-Object System.Windows.Forms.ToolStripMenuItem('&Pause')
	$menuItem.ShortcutKeys = $keys::Control -bor $keys::P
	$menuItem.Add_Click($eventHandlers.OnClickPause)
	$menuItem.CheckOnClick = $true
	[void]$menu.DropDownItems.Add($menuItem)
	$pauseMenuItem = $menuItem
	
	$menuItem = New-Object System.Windows.Forms.ToolStripMenuItem('Prior &Data')
	$menuItem.ShortcutKeys = $keys::Control -bor $keys::D
	$menuItem.Add_Click($eventHandlers.OnClickSwapData)
	$menuItem.CheckOnClick = $true
	$menuItem.Enabled = $false
	[void]$menu.DropDownItems.Add($menuItem)
	$priorDataMenuItem = $menuItem
	

	################ StatusStrip
	
	$statusStrip = New-Object System.Windows.Forms.StatusStrip
	$statusStrip.ShowItemToolTips = $true
	$form.Controls.Add($statusStrip)
	
	# NB: Omit setting any Text to maximize $commandLabel width
	# long enough for it to render.
	# (If $commandLabel is initially wider than its field width it will not show)
	$rowCountLabel = NewStatusLabel
	[void]$statusStrip.Items.add($rowCountLabel)
	
	$timingIntervalLabel = NewStatusLabel
	[void]$statusStrip.Items.add($timingIntervalLabel)
	
	$timingClockLabel = NewStatusLabel
	[void]$statusStrip.Items.add($timingClockLabel)
	
	$commandLabel = NewStatusLabel
	$commandLabel.Spring = $true
	$commandLabel.ToolTipText = $captionItems.ToolTipText
	$commandLabel.Text = $captionItems.StatusBarText
	$commandLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	[void]$statusStrip.Items.add($commandLabel)
	
	# Does not do what I expect yet...
	#Register-ObjectEvent -inputObject $grid -eventName "CellFormatting" `
	#	-action {
	#		$eventArgs = $Event.SourceEventArgs
	#		if ($eventArgs.ColumnIndex -eq 1 -and $eventArgs.RowIndex -eq 1) {
	#			$eventArgs.CellStyle.BackColor = 'Blue'
	#		}
	#	}

	return @{
		Form = $form
		Grid = $grid
		StatusStrip = $statusStrip
		RowCountLabel = $rowCountLabel
		TimingIntervalLabel = $timingIntervalLabel
		TimingClockLabel = $timingClockLabel
		CommandLabel = $commandLabel
		PauseMenuItem = $pauseMenuItem 
		PriorDataMenuItem = $priorDataMenuItem
	}
}
	
function NewStatusLabel()
{
	$label = New-Object System.Windows.Forms.ToolStripStatusLabel
	$label.BorderStyle = 'SunkenInner'
	$label.BorderSides = 'All'
	$label
}

function GenerateTimer([hashtable]$eventHandlers)
{
	$timer = New-Object System.Windows.Forms.Timer
	$timer.add_Tick($eventHandlers.OnTick)
	return @{ Timer = $timer }
}

function GetFileName($initialDirectory)
{  
	$dialog = New-Object System.Windows.Forms.SaveFileDialog
	$dialog.InitialDirectory = $initialDirectory
	$dialog.Filter = "CSV files (*.csv)|*.csv|Text files (*.txt)|*.txt|All files (*.*)|*.*" 
	$dialog.ShowDialog() | Out-Null
	$dialog.filename
}

function PopupMessage($caption, $message)
{
	[Windows.Forms.MessageBox]::Show($message, $caption,
			[Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
}

function CopyToClipboard([System.Windows.Forms.DataGridView]$grid)
{
	if ($dataObj = $grid.GetClipboardContent()) {
		[System.Windows.Forms.Clipboard]::SetDataObject($dataObj)
	}
}

