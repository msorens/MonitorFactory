
Import-Module "$PSScriptRoot\..\MonitorFactory.psd1"
. "$PSScriptRoot\..\Wrappers\StartSqlMonitor.ps1"

Describe "Start-SqlMonitor" {

	Mock Start-Monitor
	Context "validates path property" {

		It "throws error if path does not exist" {
			{ Start-SqlMonitor -path 'C:\doesnotexist.sql' -server a -database b } | Should Throw 'Cannot find path'
			Assert-MockCalled Start-Monitor 0 -Scope It
		}
		It "throws error if file is empty" {
			Mock Get-Content { return "" }
			{ Start-SqlMonitor -path 'C:\any.sql' -server a -database b } | Should Throw 'no content found'
			Assert-MockCalled Start-Monitor 0 -Scope It
		}
	}
	Context "validates other properties" {
		It "throws error if server not specified" {
			{ Start-SqlMonitor -path 'C:\any.sql' -database b } | Should Throw 'Server must be specified'
		}
		It "throws error if database not specified" {
			{ Start-SqlMonitor -path 'C:\any.sql' -server a } | Should Throw 'Database must be specified'
		}
	}
	Context "uses query" {
		It "from file content if specified" {
			$content = 'select foo from bar1'
			$targetFile = 'C:\any.sql'
			Mock Get-Content { return $content } -param { $Path -eq $targetFile }
			Start-SqlMonitor -path $targetFile -server a -database b
			Assert-MockCalled Start-Monitor 1 -Scope It { $ArgumentList[0] -eq $content }
		}
		It "from literal if specified" {
			$content = 'select foo from bar2'
			Start-SqlMonitor -query $content -server a -database b
			Assert-MockCalled Start-Monitor 1 -Scope It { $ArgumentList[0] -eq $content }
		}
	}
}

