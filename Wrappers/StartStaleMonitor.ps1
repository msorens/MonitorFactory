# Wrapper for Start-Monitor to retrieve stale TFS details by file, folder, or project.
#
# Prerequisites:
#   CleanCode\TfsTools module available from http://cleancode.sourceforge.net/wwwdoc/APIbookshelf.html
#   Visual Studio TFS 2013 PowerTools extension required--see http://bit.ly/1voD4HK
#
# Set the $path parameter default to something useful for your environment


function Start-StaleMonitor(
    [ValidateSet('file','folder','project')]$choice = 'file',
    [string]$path = 'C:\MyBase\TFS\root\Main',
    [string]$interval = '5m'
)
{
    switch($choice) {
      "file" { 
            Start-Monitor -AsJob { 
                Add-PSSnapin Microsoft.TeamFoundation.PowerShell; 
                Get-StaleTfsFiles $args[0] }    
            -Interval $interval 
            -DisplayName "Stale TFS Files [$path]" 
            -ArgumentList $path
            }
      "folder" { 
            Start-Monitor -AsJob { 
                Add-PSSnapin Microsoft.TeamFoundation.PowerShell; 
                Get-StaleTfsFolders $args[0] }  
            -Interval $interval 
            -DisplayName "Stale TFS Folders [$path]" 
            -ArgumentList $path
            }
      "project" { 
            Start-Monitor -AsJob { 
                Add-PSSnapin Microsoft.TeamFoundation.PowerShell; 
                Get-StaleTfsProjects $args[0] } 
            -Interval $interval 
            -DisplayName "Stale TFS Projects [$path]" 
            -ArgumentList $path
            }
	}
}

