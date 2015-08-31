
Set-StrictMode -Version Latest

Resolve-Path $PSScriptRoot\Components\*.ps1 |
? { -not ($_.ProviderPath.Contains(".Tests.")) } |
% { . $_.ProviderPath }
