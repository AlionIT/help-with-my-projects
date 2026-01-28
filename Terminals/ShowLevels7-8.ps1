#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =========================
# Helpers
# =========================
function Hr([string]$t) {
  Write-Host ""
  Write-Host ("=" * 110)
  Write-Host $t
  Write-Host ("=" * 110)
}

function Sub([string]$t) {
  Write-Host ""
  Write-Host ("-" * 110)
  Write-Host $t
  Write-Host ("-" * 110)
}

function Supports-VT {
  try {
    $ui = $Host.UI
    if ($null -ne $ui) {
      $p = $ui.PSObject.Properties | Where-Object { $_.Name -eq 'SupportsVirtualTerminal' }
      if ($null -ne $p) { return [bool]$ui.SupportsVirtualTerminal }
    }
  } catch { }
  return $false
}

$script:VT  = Supports-VT
$script:ESC = [char]27

function BgrDwordToRgb([int]$bgr) {
  $r =  $bgr        -band 0xFF
  $g = ($bgr -shr 8)  -band 0xFF
  $b = ($bgr -shr 16) -band 0xFF
  return [pscustomobject]@{ R=$r; G=$g; B=$b }
}

function RgbToHex([int]$r,[int]$g,[int]$b) {
  return ('#{0:X2}{1:X2}{2:X2}' -f $r,$g,$b)
}

function Decode-ConsoleColors([int]$dword) {
  $low = $dword -band 0xFF
  $fg  =  $low -band 0x0F
  $bg  = ($low -band 0xF0) -shr 4
  return [pscustomobject]@{
    DWordHex = ('0x{0:X8}' -f ($dword -band 0xFFFFFFFF))
    LowByte  = ('0x{0:X2}' -f $low)
    BGIndex  = $bg
    FGIndex  = $fg
  }
}

function Get-ColorTableName([int]$idx) {
  return ('ColorTable{0:D2}' -f $idx)
}

function Try-GetItemPropertyValue([string]$path, [string]$name) {
  try {
    return Get-ItemPropertyValue -LiteralPath $path -Name $name -ErrorAction Stop
  } catch {
    return $null
  }
}

function AnsiBgSwatch([int]$r,[int]$g,[int]$b, [string]$label = '  ') {
  if (-not $script:VT) { return '' }
  return ("{0}[48;2;{1};{2};{3}m{4}{0}[0m" -f $script:ESC, $r, $g, $b, $label)
}

function AnsiSampleText([int]$bgR,[int]$bgG,[int]$bgB,[int]$fgR,[int]$fgG,[int]$fgB,[string]$text) {
  if (-not $script:VT) { return $text }
  return ("{0}[48;2;{1};{2};{3}m{0}[38;2;{4};{5};{6}m {7} {0}[0m" -f $script:ESC, $bgR, $bgG, $bgB, $fgR, $fgG, $fgB, $text)
}

function Get-LevelTag([string]$keyPath) {
  if ($keyPath -ieq 'HKCU:\Console') { return '[L8]' }
  return '[L7]'
}

function Get-RegistryValueNoteProperties([object]$props) {
  if ($null -eq $props) {
    # Force array output even when empty
    Write-Output -NoEnumerate @()
    return
  }

  $arr = @(
    $props.PSObject.Properties |
      Where-Object {
        $_.MemberType -eq 'NoteProperty' -and
        $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider')
      }
  )

  # IMPORTANT: prevent enumeration so caller always receives an array object
  Write-Output -NoEnumerate $arr
}

# =========================
# Core printer
# =========================
function Show-ConsoleKeyDetailed([string]$keyPath, [string]$title) {
  $tag = Get-LevelTag $keyPath
  Hr "$tag $title"
  Write-Host "$tag Path: $keyPath"
  Write-Host "$tag VT  : $($script:VT)"

  if (-not (Test-Path -LiteralPath $keyPath)) {
    Write-Host "$tag State: MISSING (registry key not found)"
    return
  }

  Write-Host "$tag State: EXISTS"

  $props = $null
  try {
    $props = Get-ItemProperty -LiteralPath $keyPath -ErrorAction Stop
  } catch {
    Write-Host "$tag ERROR: cannot read key -> $($_.Exception.Message)"
    return
  }

  # --- Core colors
  Sub "$tag Core colors (ScreenColors / PopupColors)"
  $scRaw = Try-GetItemPropertyValue $keyPath 'ScreenColors'
  $pcRaw = Try-GetItemPropertyValue $keyPath 'PopupColors'

  $scObj = $null
  if ($null -ne $scRaw) {
    $scObj = Decode-ConsoleColors ([int]$scRaw)
    Write-Host ("{0} ScreenColors: {1} low={2} BG={3} FG={4}" -f $tag, $scObj.DWordHex, $scObj.LowByte, $scObj.BGIndex, $scObj.FGIndex)
  } else {
    Write-Host ("{0} ScreenColors: (not set)" -f $tag)
  }

  $pcObj = $null
  if ($null -ne $pcRaw) {
    $pcObj = Decode-ConsoleColors ([int]$pcRaw)
    Write-Host ("{0} PopupColors : {1} low={2} BG={3} FG={4}" -f $tag, $pcObj.DWordHex, $pcObj.LowByte, $pcObj.BGIndex, $pcObj.FGIndex)
  } else {
    Write-Host ("{0} PopupColors : (not set)" -f $tag)
  }

  # --- Palette
  Sub "$tag Palette (ColorTable00..15): BGR DWORD -> RGB -> HEX + sample"
  $palette = @{}
  for ($i = 0; $i -lt 16; $i++) {
    $nm  = Get-ColorTableName $i
    $val = Try-GetItemPropertyValue $keyPath $nm

    if ($null -eq $val) {
      Write-Host ("{0} [{1:D2}] {2,-12} = (not set)" -f $tag, $i, $nm)
      continue
    }

    $ival = [int]$val
    $rgb  = BgrDwordToRgb $ival
    $hex  = RgbToHex $rgb.R $rgb.G $rgb.B
    $dw   = ('0x{0:X8}' -f ($ival -band 0xFFFFFFFF))
    $sw   = AnsiBgSwatch $rgb.R $rgb.G $rgb.B '  '

    $palette[$i] = [pscustomobject]@{ Index=$i; Name=$nm; Dword=$ival; R=$rgb.R; G=$rgb.G; B=$rgb.B; Hex=$hex }
    Write-Host ("{0} [{1:D2}] {2,-12} = {3} -> RGB({4,3},{5,3},{6,3}) {7} {8}" -f $tag, $i, $nm, $dw, $rgb.R, $rgb.G, $rgb.B, $hex, $sw)
  }

  # --- Effective window colors
  if ($null -ne $scObj) {
    Sub "$tag Effective window colors (from ScreenColors)"
    $bgOk = $palette.ContainsKey($scObj.BGIndex)
    $fgOk = $palette.ContainsKey($scObj.FGIndex)

    if ($bgOk) {
      $bg = $palette[$scObj.BGIndex]
      Write-Host ("{0} BG ColorTable[{1}] = {2} {3}" -f $tag, $bg.Index, $bg.Hex, (AnsiBgSwatch $bg.R $bg.G $bg.B '  '))
    } else {
      Write-Host ("{0} BG ColorTable[{1}] = (not set)" -f $tag, $scObj.BGIndex)
    }

    if ($fgOk) {
      $fg = $palette[$scObj.FGIndex]
      Write-Host ("{0} FG ColorTable[{1}] = {2} {3}" -f $tag, $fg.Index, $fg.Hex, (AnsiBgSwatch $fg.R $fg.G $fg.B '  '))
    } else {
      Write-Host ("{0} FG ColorTable[{1}] = (not set)" -f $tag, $scObj.FGIndex)
    }

    if ($bgOk -and $fgOk) {
      $bg = $palette[$scObj.BGIndex]
      $fg = $palette[$scObj.FGIndex]
      $sample = AnsiSampleText $bg.R $bg.G $bg.B $fg.R $fg.G $fg.B ("SAMPLE BG={0} / FG={1}" -f $scObj.BGIndex, $scObj.FGIndex)
      Write-Host ("{0} {1}" -f $tag, $sample)
    } else {
      Write-Host ("{0} Sample: cannot render (missing BG/FG ColorTable values)" -f $tag)
    }
  }

  # --- Popup sample
  if ($null -ne $pcObj) {
    Sub "$tag Popup colors (from PopupColors)"
    $bgOk = $palette.ContainsKey($pcObj.BGIndex)
    $fgOk = $palette.ContainsKey($pcObj.FGIndex)

    if ($bgOk) {
      $bg = $palette[$pcObj.BGIndex]
      Write-Host ("{0} POPUP BG ColorTable[{1}] = {2} {3}" -f $tag, $bg.Index, $bg.Hex, (AnsiBgSwatch $bg.R $bg.G $bg.B '  '))
    } else {
      Write-Host ("{0} POPUP BG ColorTable[{1}] = (not set)" -f $tag, $pcObj.BGIndex)
    }

    if ($fgOk) {
      $fg = $palette[$pcObj.FGIndex]
      Write-Host ("{0} POPUP FG ColorTable[{1}] = {2} {3}" -f $tag, $fg.Index, $fg.Hex, (AnsiBgSwatch $fg.R $fg.G $fg.B '  '))
    } else {
      Write-Host ("{0} POPUP FG ColorTable[{1}] = (not set)" -f $tag, $pcObj.FGIndex)
    }

    if ($bgOk -and $fgOk) {
      $bg = $palette[$pcObj.BGIndex]
      $fg = $palette[$pcObj.FGIndex]
      $sample = AnsiSampleText $bg.R $bg.G $bg.B $fg.R $fg.G $fg.B ("POPUP SAMPLE BG={0} / FG={1}" -f $pcObj.BGIndex, $pcObj.FGIndex)
      Write-Host ("{0} {1}" -f $tag, $sample)
    } else {
      Write-Host ("{0} Popup sample: cannot render (missing BG/FG ColorTable values)" -f $tag)
    }
  }

  # --- Other params (safe reads)
  Sub "$tag Other console params (raw, safe reads)"
  $other = @(
    'FaceName','FontSize','FontFamily','FontWeight',
    'WindowSize','ScreenBufferSize','WindowPosition',
    'QuickEdit','InsertMode','CursorSize','HistoryNoDup',
    'NumberOfHistoryBuffers','HistoryBufferSize','ForceV2',
    'VirtualTerminalLevel'
  )

  foreach ($n in $other) {
    $v = Try-GetItemPropertyValue $keyPath $n
    if ($null -eq $v) {
      Write-Host ("{0} {1} = (not set)" -f $tag, $n)
    } else {
      Write-Host ("{0} {1} = {2}" -f $tag, $n, $v)
    }
  }

  # --- All value names (robust Count)
  Sub "$tag All registry values in this key (NoteProperty list)"
  $vals = @((Get-RegistryValueNoteProperties $props))  # <- force array ALWAYS
  if ($vals.Count -eq 0) {
    Write-Host ("{0} (no values)" -f $tag)
  } else {
    foreach ($p in ($vals | Sort-Object Name)) {
      $s = [string]$p.Value
      if ($s.Length -gt 180) { $s = $s.Substring(0,180) + '...' }
      Write-Host ("{0} - {1} = {2}" -f $tag, $p.Name, $s)
    }
  }
}

# =========================
# MAIN
# =========================
Hr "Discover pwsh console keys under HKCU:\Console"
$root = 'HKCU:\Console'

$children = @()
try {
  $children = @((Get-ChildItem -LiteralPath $root -ErrorAction Stop))  # <- force array
} catch {
  Write-Host "ERROR: cannot enumerate HKCU:\Console -> $($_.Exception.Message)"
  $children = @()
}

$pwshKeys = @()
if ($children.Count -gt 0) {
  $pwshKeys = @(
    $children |
      Where-Object { $_.PSChildName -match '(?i)pwsh' } |
      Select-Object -ExpandProperty PSChildName
  )
}

if ($pwshKeys.Count -eq 0) {
  Write-Host "[L7] pwsh keys: NONE (Level 7 is absent)"
} else {
  Write-Host "[L7] pwsh keys found:"
  $pwshKeys | Sort-Object | ForEach-Object { Write-Host ("[L7] - {0}" -f $_) }
}

# Level 8
Show-ConsoleKeyDetailed -keyPath $root -title 'LEVEL 8: HKCU:\Console (global base)'

# Level 7
if ($pwshKeys.Count -gt 0) {
  foreach ($k in ($pwshKeys | Sort-Object)) {
    $kp = Join-Path $root $k
    Show-ConsoleKeyDetailed -keyPath $kp -title ("LEVEL 7: HKCU:\Console\{0}" -f $k)
  }
} else {
  Hr "[L7] LEVEL 7: nothing to show"
}

Hr "DONE"
Write-Host "Tip: ConHost reads HKCU:\Console at process start. If you changed registry, close ALL console windows and reopen."
