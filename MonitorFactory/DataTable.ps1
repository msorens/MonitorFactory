Set-StrictMode -Version Latest

function OutDataTable {
	
	$dataTable = New-Object Data.DataTable
	$first = $true
	
	foreach ($item in $input) {
		$row = $dataTable.NewRow()
		$item.PsObject.get_properties() | foreach {
			if ($first) {
				$Col = New-Object Data.DataColumn
				$Col.ColumnName = $_.Name.ToString()
				$dataTable.Columns.Add($Col)
			}
			if ($_.value -eq $null) {
				$row[$_.Name] = '[empty]'
			}
			elseif ($_ -is [array]) {
				$row[$_.Name] = $_.value -join ';'
			}
			elseif ($dataTable.Columns.Contains($_.Name)) {
				$row[$_.Name] = $_.value
			}
		}
		$dataTable.Rows.Add($row)
		$first = $false
	}

	return @(,($dataTable)) # necessary... but not quite sure why
}
