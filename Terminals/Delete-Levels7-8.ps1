<#
.SYNOPSIS
    Полная очистка (wipe) консольных настроек ConHost для PowerShell 7 (pwsh) на уровнях 7 и 8 в реестре,
    с опциональной записью базовых (baseline) значений.

.DESCRIPTION
    Скрипт работает с классическими настройками Windows ConsoleHost (ConHost), которые хранятся в реестре:

    - Уровень 8 (глобальная база):   HKCU:\Console
      Содержит глобальную палитру (ColorTable00..15), ScreenColors, PopupColors и другие параметры консоли.

    - Уровень 7 (пер-приложение):    HKCU:\Console\<ключи содержащие pwsh>
      Персональные overrides для конкретного приложения. Если они существуют, они могут перекрывать Уровень 8
      именно для pwsh/ConHost.

    Что делает скрипт:
    1) Находит и удаляет ВСЕ ключи уровня 7 под HKCU:\Console, в имени которых есть "*pwsh*".
    2) Очищает ВСЕ значения в HKCU:\Console (Уровень 8).
    3) Опционально записывает минимальный Windows baseline в Уровень 8 (палитра + ScreenColors/PopupColors).

    Вывод в консоль:
    - Печатает снимки ДО/ПОСЛЕ для Уровня 8.
    - Для каждого найденного ключа Уровня 7 печатает ДО/ПОСЛЕ и результат удаления.
    - Палитру показывает как BGR DWORD -> RGB -> HEX и (если доступно VT) может рисовать ANSI-образцы цветов.

.PARAMETER Mode
    Необязательный параметр. Определяет, каким станет Уровень 8 после очистки.

    - Empty    : (по умолчанию) оставляет HKCU:\Console БЕЗ значений (чистый лист).
    - Baseline : после очистки записывает Windows-подобный baseline: палитра + ScreenColors/PopupColors.

    ВАЖНО:
    - Скрипт меняет только HKCU (текущий пользователь).
    - ConHost читает эти параметры при СТАРТЕ ПРОЦЕССА. Открытые окна не “перекрасятся” на лету.

.EXAMPLE
    # По умолчанию: удалить уровень 7 (pwsh) и очистить уровень 8 (оставить пусто)
    .\Delete-Levels7-8.ps1

.EXAMPLE
    # Удалить уровень 7 (pwsh) и очистить уровень 8, затем записать baseline
    .\Delete-Levels7-8.ps1 Baseline

.EXAMPLE
    # Типовой сценарий для воспроизводимого “чистого листа”
    .\Delete-Levels7-8.ps1 Empty
    # Закрыть ВСЕ окна pwsh/ConHost
    # Открыть pwsh заново и проверить:
    .\ShowLevels7-8.ps1
    # Если нужны дефолты Windows:
    .\Delete-Levels7-8.ps1 Baseline

.NOTES
    Рекомендуемая последовательность (чтобы не ловить “магический кеш” ярлыков/панели задач):
    1) Запусти этот скрипт (Empty или Baseline).
    2) Закрой ВСЕ окна ConHost/pwsh.
    3) Запусти pwsh заново (Win+R -> pwsh).
    4) Только после того, как Уровень 8 в нужном состоянии, создавай/закрепляй ярлык на панели задач,
       потому что Windows может скопировать текущие свойства консоли в ярлык в момент его создания.

    Безопасность:
    - Бэкапы намеренно НЕ делаются (мы работаем в режиме clean-slate).
    - Если хочешь сохранить текущую палитру — заранее экспортируй HKCU:\Console вручную.

.REQUIREMENTS
    - Рекомендуется PowerShell 7+ (pwsh).
    - Админ-права не нужны (пишем в HKCU).

#>
#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =========================
# Mode (NO param)
# Usage:
#   .\Delete-Levels7-8.ps1           -> Mode=Empty
#   .\Delete-Levels7-8.ps1 Empty
#   .\Delete-Levels7-8.ps1 Baseline  -> wipe + write Windows baseline palette + ScreenColors/PopupColors
# =========================
$Mode = 'Empty'
if ($args.Count -ge 1 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) {
  $Mode = ([string]$args[0]).Trim()
}
if ($Mode -notin @('Empty','Baseline')) {
  Write-Host ""
  Write-Host "ERROR: Unknown mode: '$Mode'   Allowed: Empty | Baseline"
  exit 2
}

# =========================
# Formatting helpers (ASCII-only)
# =========================
function Hr([string]$t) {
  Write-Host ""
  Write-Host ("=" * 120)
  Write-Host $t
  Write-Host ("=" * 120)
}
function Sub([string]$t) {
  Write-Host ""
  Write-Host ("-" * 120)
  Write-Host $t
  Write-Host ("-" * 120)
}

# =========================
# Safe property checks
# =========================
function Has-Prop([object]$o, [string]$name) {
  if ($null -eq $o) { return $false }
  try { return ($null -ne $o.PSObject.Properties[$name]) } catch { return $false }
}
function Get-Prop([object]$o, [string]$name) {
  if (Has-Prop $o $name) { return $o.$name }
  return $null
}

# =========================
# Console/VT helpers
# =========================
function Supports-VT {
  try {
    $ui = $Host.UI
    if ($null -ne $ui -and (Has-Prop $ui 'SupportsVirtualTerminal')) {
      return [bool]$ui.SupportsVirtualTerminal
    }
  } catch { }
  return $false
}

$script:VT  = Supports-VT
$script:ESC = [char]27

function BgrDwordToRgb([int]$bgr) {
  $r =  $bgr         -band 0xFF
  $g = ($bgr -shr 8)  -band 0xFF
  $b = ($bgr -shr 16) -band 0xFF
  [pscustomobject]@{ R=$r; G=$g; B=$b }
}
function RgbToHex([int]$r,[int]$g,[int]$b) { ('#{0:X2}{1:X2}{2:X2}' -f $r,$g,$b) }

function Decode-ConsoleColors([int]$dword) {
  $low = $dword -band 0xFF
  $fg  =  $low -band 0x0F
  $bg  = ($low -band 0xF0) -shr 4
  [pscustomobject]@{
    DWordHex = ('0x{0:X8}' -f ($dword -band 0xFFFFFFFF))
    LowByte  = ('0x{0:X2}' -f $low)
    BGIndex  = $bg
    FGIndex  = $fg
  }
}

function Get-RegValueNames([object]$props) {
  if ($null -eq $props) { return @() }
  @(
    $props.PSObject.Properties |
      Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') } |
      Select-Object -ExpandProperty Name
  )
}

function Get-ColorTableName([int]$idx) { ('ColorTable{0:D2}' -f $idx) }

function Get-ColorTableValue([object]$props, [int]$idx) {
  $name = Get-ColorTableName $idx
  if (Has-Prop $props $name) { return [int]$props.$name }
  return $null
}

function Ansi-Swatch([int]$r,[int]$g,[int]$b) {
  if (-not $script:VT) { return '' }
  ("{0}[48;2;{1};{2};{3}m  {0}[0m" -f $script:ESC, $r, $g, $b)
}

# =========================
# Snapshot + printing
# =========================
function Take-ConsoleSnapshot([string]$path) {
  $exists = Test-Path -LiteralPath $path
  $props  = if ($exists) { Get-ItemProperty -LiteralPath $path -ErrorAction Stop } else { $null }

  $palette = @()
  for ($i=0; $i -lt 16; $i++) {
    $v = Get-ColorTableValue $props $i
    if ($null -eq $v) {
      $palette += [pscustomobject]@{
        Index=$i; Name=(Get-ColorTableName $i); Exists=$false; Dword=$null; DwordHex=$null; R=$null; G=$null; B=$null; Hex=$null
      }
      continue
    }
    $rgb = BgrDwordToRgb $v
    $palette += [pscustomobject]@{
      Index=$i; Name=(Get-ColorTableName $i); Exists=$true; Dword=$v;
      DwordHex=('0x{0:X8}' -f ($v -band 0xFFFFFFFF));
      R=$rgb.R; G=$rgb.G; B=$rgb.B; Hex=(RgbToHex $rgb.R $rgb.G $rgb.B)
    }
  }

  $screen = $null
  if ($exists -and (Has-Prop $props 'ScreenColors')) {
    $screen = Decode-ConsoleColors ([int]$props.ScreenColors)
  }
  $popup = $null
  if ($exists -and (Has-Prop $props 'PopupColors')) {
    $popup = Decode-ConsoleColors ([int]$props.PopupColors)
  }

  $vals = @{}
  if ($exists) {
    foreach ($n in (Get-RegValueNames $props)) { $vals[$n] = $props.$n }
  }

  [pscustomobject]@{
    Path=$path; Exists=$exists; Values=$vals;
    Palette=$palette; Screen=$screen; Popup=$popup
  }
}

function Print-ConsoleSnapshot([object]$snap, [string]$label) {
  Hr $label
  Write-Host ("Path : {0}" -f $snap.Path)
  Write-Host ("State: {0}" -f $(if ($snap.Exists) { 'EXISTS' } else { 'MISSING' }))
  if (-not $snap.Exists) { return }

  Sub "Core colors (ScreenColors / PopupColors)"
  if ($null -ne $snap.Screen) {
    Write-Host ("ScreenColors: {0} low={1} BG={2} FG={3}" -f $snap.Screen.DWordHex, $snap.Screen.LowByte, $snap.Screen.BGIndex, $snap.Screen.FGIndex)
    $bg = ($snap.Palette | Where-Object { $_.Index -eq $snap.Screen.BGIndex } | Select-Object -First 1)
    $fg = ($snap.Palette | Where-Object { $_.Index -eq $snap.Screen.FGIndex } | Select-Object -First 1)
    if ($null -ne $bg -and $bg.Exists) { Write-Host ("  BG ColorTable[{0}] = {1} {2}" -f $bg.Index, $bg.Hex, (Ansi-Swatch $bg.R $bg.G $bg.B)) }
    if ($null -ne $fg -and $fg.Exists) { Write-Host ("  FG ColorTable[{0}] = {1} {2}" -f $fg.Index, $fg.Hex, (Ansi-Swatch $fg.R $fg.G $fg.B)) }
  } else {
    Write-Host "ScreenColors: (not set)"
  }

  if ($null -ne $snap.Popup) {
    Write-Host ("PopupColors : {0} low={1} BG={2} FG={3}" -f $snap.Popup.DWordHex, $snap.Popup.LowByte, $snap.Popup.BGIndex, $snap.Popup.FGIndex)
  } else {
    Write-Host "PopupColors : (not set)"
  }

  Sub "Palette (ColorTable00..15): BGR DWORD -> RGB -> HEX + sample (ANSI if VT supported)"
  foreach ($c in $snap.Palette) {
    if (-not $c.Exists) {
      Write-Host ("[{0:D2}] {1,-12} = (not set)" -f $c.Index, $c.Name)
      continue
    }
    $sample = Ansi-Swatch $c.R $c.G $c.B
    Write-Host ("[{0:D2}] {1,-12} = {2} -> RGB({3,3},{4,3},{5,3}) {6} {7}" -f $c.Index, $c.Name, $c.DwordHex, $c.R, $c.G, $c.B, $c.Hex, $sample)
  }

  Sub "All value names in this key"
  $names = @($snap.Values.Keys | Sort-Object)
  if ($names.Count -eq 0) { Write-Host "(no values)"; return }
  foreach ($n in $names) {
    $v = $snap.Values[$n]
    $s = [string]$v
    if ($s.Length -gt 160) { $s = $s.Substring(0,160) + '...' }
    Write-Host ("- {0} = {1}" -f $n, $s)
  }
}

# =========================
# Registry helpers
# =========================
function Ensure-Key([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { New-Item -Path $path -Force | Out-Null }
}

function Remove-All-Values([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return @() }
  $props = Get-ItemProperty -LiteralPath $path -ErrorAction Stop
  $names = @((Get-RegValueNames $props))
  foreach ($n in $names) {
    try { Remove-ItemProperty -LiteralPath $path -Name $n -Force -ErrorAction Stop } catch { }
  }
  $names
}

function Set-Dword([string]$path, [string]$name, [int]$value) {
  $p = Get-ItemProperty -LiteralPath $path -ErrorAction SilentlyContinue
  if ($null -ne $p -and (Has-Prop $p $name)) {
    Set-ItemProperty -LiteralPath $path -Name $name -Value $value
  } else {
    New-ItemProperty -LiteralPath $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
  }
}

# =========================
# Windows baseline palette (BGR DWORDs)
# =========================
$winDefaultPaletteBgr = @(
  0x000C0C0C, 0x00DA3700, 0x000EA113, 0x00DD963A,
  0x001F0FC5, 0x00981788, 0x00009CC1, 0x00CCCCCC,
  0x00767676, 0x00FF783B, 0x000CC616, 0x00D6D661,
  0x005648E7, 0x009E00B4, 0x00A5F1F9, 0x00F2F2F2
)

$level8Path = 'HKCU:\Console'

# =========================
# MAIN
# =========================
Hr "Wipe pwsh console settings on Level 7, and wipe/reset Level 8"
Write-Host ("Mode: {0}" -f $Mode)
Write-Host ("Host: {0}" -f $Host.Name)
Write-Host ("VT  : {0}" -f $(if ($script:VT) { 'YES' } else { 'NO (ANSI swatches blank)' }))
Write-Host ""
Write-Host "NOTE: ConHost reads HKCU:\Console at process start. Reopen pwsh after running this script."

Sub "Discovering Level 7 keys (HKCU:\Console\*pwsh*)"
$children = Get-ChildItem -LiteralPath $level8Path -ErrorAction SilentlyContinue
$pwshChildNames = @()
if ($children) {
  $pwshChildNames = $children | Where-Object { $_.PSChildName -match '(?i)pwsh' } | Select-Object -ExpandProperty PSChildName
}
$pwshChildNames = @($pwshChildNames)

if ($pwshChildNames.Count -eq 0) {
  Write-Host "Found: none"
} else {
  Write-Host "Found:"
  $pwshChildNames | Sort-Object | ForEach-Object { Write-Host ("- {0}" -f $_) }
}

$before8 = Take-ConsoleSnapshot $level8Path
Print-ConsoleSnapshot $before8 "LEVEL 8 BEFORE (HKCU:\Console)"

if ($pwshChildNames.Count -gt 0) {
  foreach ($child in ($pwshChildNames | Sort-Object)) {
    $kpath = Join-Path $level8Path $child
    $b = Take-ConsoleSnapshot $kpath
    Print-ConsoleSnapshot $b ("LEVEL 7 BEFORE ({0})" -f $child)

    Sub ("Deleting LEVEL 7 key: {0}" -f $kpath)
    try {
      Remove-Item -LiteralPath $kpath -Recurse -Force -ErrorAction Stop
      Write-Host "Deleted: OK"
    } catch {
      Write-Host ("Deleted: FAIL -> {0}" -f $_.Exception.Message)
    }

    $a = Take-ConsoleSnapshot $kpath
    Print-ConsoleSnapshot $a ("LEVEL 7 AFTER  ({0})" -f $child)
  }
} else {
  Sub "No Level 7 pwsh keys to delete"
}

Sub "LEVEL 8 action: remove ALL values (and optionally write baseline)"
Ensure-Key $level8Path

$removedNames = @(Remove-All-Values $level8Path)
Write-Host ("Removed value count: {0}" -f $removedNames.Count)
if ($removedNames.Count -gt 0) {
  Write-Host "Removed value names:"
  $removedNames | Sort-Object | ForEach-Object { Write-Host ("- {0}" -f $_) }
} else {
  Write-Host "Removed value names: (none)"
}

try {
  $verifyProps = Get-ItemProperty -LiteralPath $level8Path -ErrorAction Stop
  $verifyNames = @((Get-RegValueNames $verifyProps))
  Write-Host ("After wipe (immediate read), value count in HKCU:\Console = {0}" -f $verifyNames.Count)
} catch {
  Write-Host ("After wipe (immediate read), cannot read key: {0}" -f $_.Exception.Message)
}

if ($Mode -eq 'Baseline') {
  Sub "Writing Windows baseline (palette + ScreenColors/PopupColors)"
  for ($i=0; $i -lt 16; $i++) {
    $nm = Get-ColorTableName $i
    Set-Dword $level8Path $nm ([int]$winDefaultPaletteBgr[$i])
  }
  Set-Dword $level8Path 'ScreenColors' 0x00000007
  Set-Dword $level8Path 'PopupColors'  0x000000F5
}

$after8 = Take-ConsoleSnapshot $level8Path
Print-ConsoleSnapshot $after8 ("LEVEL 8 AFTER  (HKCU:\Console)  Mode={0}" -f $Mode)

Hr "DONE"
Write-Host "Next steps:"
Write-Host "1) Close ALL ConHost/pwsh windows."
Write-Host "2) Start pwsh again (Win+R -> pwsh)."
Write-Host "3) Pin to taskbar only AFTER Level 8 is in the state you want."
