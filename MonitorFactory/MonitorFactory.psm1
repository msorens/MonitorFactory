#
# ==============================================================
# @ID       $Id: MonitorFactory.psm1 1528 2015-07-12 03:29:08Z ms $
# @created  2011-08-25
# @project  http://cleancode.sourceforge.net/
# ==============================================================

Set-StrictMode -Version Latest

Resolve-Path $PSScriptRoot\*.ps1 |
? { -not ($_.ProviderPath.Contains(".Tests.")) } |
% { . $_.ProviderPath }
