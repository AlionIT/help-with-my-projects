#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$needles = @(
  '3270', 'BigBlue', 'Caskaydia', 'ComicShanns', 'Cousine',
  'FiraMono', 'JetBrainsMono', 'RobotoMono', 'SpaceMono', 'Nerd'
)

$fontsKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
$props = Get-ItemProperty -LiteralPath $fontsKey

$rows =
  $props.PSObject.Properties |
  Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') } |
  Where-Object {
    $n = $_.Name
    ($needles | ForEach-Object { $n -match [regex]::Escape($_) }) -contains $true
  } |
  ForEach-Object {
    $regName = $_.Name
    $file    = [string]$_.Value

    # Обычно family, которое надо в настройках, это часть до " (TrueType)"
    $family = $regName
    if ($family -match '^\s*(.+?)\s*\(TrueType\)\s*$') { $family = $Matches[1] }
    elseif ($family -match '^\s*(.+?)\s*\(OpenType\)\s*$') { $family = $Matches[1] }

    [pscustomobject]@{
      FamilyToUse = $family
      RegistryName = $regName
      File = $file
    }
  } |
  Sort-Object FamilyToUse -Unique

if (-not $rows -or $rows.Count -eq 0) {
  Write-Host "Ничего не найдено по заданным ключевым словам. Проверь установку шрифтов."
  exit 0
}

Write-Host "ИМЕННО ЭТИ значения копируй в настройки (WT font.face / VSCode terminal.integrated.fontFamily):"
$rows | ForEach-Object { Write-Host ("- {0}" -f $_.FamilyToUse) }

Write-Host ""
Write-Host "Подробности (что откуда взялось):"
$rows | Format-Table -AutoSize
