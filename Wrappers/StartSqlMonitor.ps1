# Wrapper for Start-Monitor to execute SQL code from a file

function Start-SqlMonitor (
    [Parameter(ParameterSetName='FileQuery', Mandatory)][string]$path,
    [Parameter(ParameterSetName='InlineQuery', Mandatory)][string]$query,
    [Parameter(Mandatory)][string]$server,
    [Parameter(Mandatory)][string]$database,
    [string]$title = '',
    [string]$interval = '5sec'
)
{
    if ($path) { $query = Get-Content $path }
    $monitorParams = @{
        AsJob = $true
        Interval = $interval
        ScriptBlock = {
            $results = Invoke-Sqlcmd -Query $args[0] -Server $args[1] -Database $args[2]
            if ($results) {
                # Filters out meta-columns added by PowerShell bug
                $names = ($results[0] | Get-Member -Type property).Name
                $results | Select-Object $names
            }
        }
        ArgumentList = $query, $server, $database
    }
    if ($title) { $monitorParams.DisplayName = $title }
    Start-Monitor @monitorParams
} 

