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
            Invoke-Sqlcmd -InputFile $args[0] -Server $args[1] -Database $args[2]
        }
        ArgumentList = $path, $server, $database
    }
    if ($title) { $monitorParams.DisplayName = $title }
    Start-Monitor @monitorParams
} 

