# Wrapper for Start-Monitor to execute SQL code from a file

function Start-SqlMonitor (
    [string]$path,
    [string]$server,
    [string]$database,
    [string]$title = '',
    [string]$interval = '5sec'
)
{
    $monitorParams = @{
        AsJob = $true
        Interval = $interval
        ScriptBlock = {
            $results = Invoke-Sqlcmd -InputFile $args[0] -Server $args[1] -Database $args[2]
			$names = ($results[0] | Get-Member -Type property).Name
			$results | Select-Object $names
        }
        ArgumentList = $path, $server, $database
    }
    if ($title) { $monitorParams.DisplayName = $title }
    Start-Monitor @monitorParams
} 

