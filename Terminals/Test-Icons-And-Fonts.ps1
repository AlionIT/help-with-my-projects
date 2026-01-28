#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =====================================================================
# Test-Glyphs.ps1
# Проверка отображения символов/иконок в текущем хосте (ConHost / WT / VSCode)
# =====================================================================

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
    if ($null -ne $ui -and $ui.PSObject.Properties.Name -contains 'SupportsVirtualTerminal') {
      return [bool]$ui.SupportsVirtualTerminal
    }
  } catch { }
  return $false
}

function Try-GetChcp {
  try {
    # cmd покажет активную OEM codepage (на ConHost может влиять на нек-рые выводы/внешние команды)
    $out = & cmd.exe /c chcp 2>$null
    if ($out) { return ($out -join "`n").Trim() }
  } catch { }
  return "(chcp unavailable)"
}

function Build-FromCodepoints([int[]]$cps) {
  $sb = [System.Text.StringBuilder]::new()
  foreach ($cp in $cps) {
    if ($cp -le 0xFFFF) {
      [void]$sb.Append([char]$cp)
    } else {
      [void]$sb.Append([char]::ConvertFromUtf32($cp))
    }
  }
  return $sb.ToString()
}

function Format-Codepoints([int[]]$cps) {
  return ($cps | ForEach-Object { ('U+{0:X4}' -f $_) }) -join ' '
}

function Write-Methods([string]$prefix, [string]$s) {
  # 3 разных пути вывода: иногда помогает понять "кодировка vs шрифт vs хост"
  Write-Host ("{0} [Write-Host     ] {1}" -f $prefix, $s)
  Write-Output ("{0} [Write-Output   ] {1}" -f $prefix, $s)
  [Console]::WriteLine(("{0} [Console.Write  ] {1}" -f $prefix, $s))
}

function Test-Items([string]$title, [object[]]$items) {
  Hr $title

  foreach ($it in $items) {
    $s = Build-FromCodepoints $it.Cps
    $cpText = Format-Codepoints $it.Cps
    $name = $it.Name
    $note = $it.Note

    Sub ("{0}  ({1})" -f $name, $cpText)
    if ($note) { Write-Host ("Note: {0}" -f $note) }

    # Печатаем как строку + как "вставку" в квадратные скобки, чтобы было видно границы
    $demo = "[$s]  $s  $s"
    Write-Methods "TEST" $demo
  }
}

# =========================
# ENV INFO
# =========================
$vt = Supports-VT

Hr "ENV / HOST INFO"
Write-Host ("Host.Name            : {0}" -f $Host.Name)
Write-Host ("PSVersion            : {0}" -f $PSVersionTable.PSVersion)
Write-Host ("WT_SESSION           : {0}" -f ($(if ($env:WT_SESSION) { $env:WT_SESSION } else { '(empty)' })))
Write-Host ("TERM_PROGRAM         : {0}" -f ($(if ($env:TERM_PROGRAM) { $env:TERM_PROGRAM } else { '(empty)' })))
Write-Host ("VSCODE_PID           : {0}" -f ($(if ($env:VSCODE_PID) { $env:VSCODE_PID } else { '(empty)' })))
Write-Host ("Supports VT (host)   : {0}" -f $vt)
Write-Host ("chcp                 : {0}" -f (Try-GetChcp))
Write-Host ("[Console] OutputEnc  : {0} / {1}" -f [Console]::OutputEncoding.WebName, [Console]::OutputEncoding.EncodingName)
Write-Host ("[Console] InputEnc   : {0} / {1}" -f [Console]::InputEncoding.WebName,  [Console]::InputEncoding.EncodingName)
Write-Host ("`$OutputEncoding      : {0}" -f ($(if ($null -ne $OutputEncoding) { $OutputEncoding.WebName } else { '(null)' })))

# =========================
# TEST SETS
# =========================
$items = @(
  # Базовые (ASCII + стрелки/бокс-дроинг/блоки)
  [pscustomobject]@{ Name = 'ASCII baseline'; Cps = @(0x0041,0x0042,0x0043,0x0020,0x0031,0x0032,0x0033); Note='Должно отображаться всегда' },
  [pscustomobject]@{ Name = 'Arrow'; Cps = @(0x2192); Note='Стрелка (часто есть почти везде)' },
  [pscustomobject]@{ Name = 'Box drawing'; Cps = @(0x2500,0x2502,0x2514,0x2518,0x250C,0x2510,0x253C); Note='Линии/рамки' },
  [pscustomobject]@{ Name = 'Block elements'; Cps = @(0x2588,0x2593,0x2592,0x2591); Note='Заполненные блоки (обычно есть)' },

  # BMP символы (Dingbats / Misc Symbols) — часто ломаются при неправильной кодировке/шрифте
  [pscustomobject]@{ Name = 'Check mark'; Cps = @(0x2713); Note='✓ (BMP)' },
  [pscustomobject]@{ Name = 'Heavy check'; Cps = @(0x2714); Note='✔ (BMP)' },
  [pscustomobject]@{ Name = 'Black star'; Cps = @(0x2605); Note='★ (BMP)' },
  [pscustomobject]@{ Name = 'Warning sign text'; Cps = @(0x26A0); Note='⚠ (BMP, без VS16)' },
  [pscustomobject]@{ Name = 'Warning sign emoji'; Cps = @(0x26A0,0xFE0F); Note='⚠️ (BMP + VS16, просит emoji presentation)' },

  # Немного “обычной” юникодной математики/греческих
  [pscustomobject]@{ Name = 'Greek pi'; Cps = @(0x03C0); Note='π (BMP)' },
  [pscustomobject]@{ Name = 'Summation'; Cps = @(0x2211); Note='∑ (BMP)' },
  [pscustomobject]@{ Name = 'Cyrillic'; Cps = @(0x041F,0x0440,0x0438,0x0432,0x0435,0x0442); Note='Привет (проверка кириллицы)' },

  # Emoji (Supplementary Planes)
  [pscustomobject]@{ Name = 'Globe'; Cps = @(0x1F30D); Note='🌍 (emoji)' },
  [pscustomobject]@{ Name = 'Dart'; Cps = @(0x1F3AF); Note='🎯 (emoji)' },
  [pscustomobject]@{ Name = 'White heavy check mark'; Cps = @(0x2705); Note='✅ (emoji-ish, часто как emoji)' },
  [pscustomobject]@{ Name = 'Rocket'; Cps = @(0x1F680); Note='🚀 (emoji)' },

  # Составные emoji (ZWJ / флаги / тон кожи)
  [pscustomobject]@{ Name = 'Woman technologist (ZWJ)'; Cps = @(0x1F469,0x200D,0x1F4BB); Note='👩‍💻 (ZWJ sequence)' },
  [pscustomobject]@{ Name = 'US flag'; Cps = @(0x1F1FA,0x1F1F8); Note='🇺🇸 (regional indicators)' },
  [pscustomobject]@{ Name = 'Thumbs up + skin tone'; Cps = @(0x1F44D,0x1F3FD); Note='👍🏽 (emoji + modifier)' },

  # Nerd Font / Powerline (Private Use Area) — покажет, установлен ли патченный шрифт
  [pscustomobject]@{ Name = 'Powerline separator (PUA)'; Cps = @(0xE0B0,0xE0B1,0xE0B2,0xE0B3); Note='Только если шрифт Powerline/NerdFont' },
  [pscustomobject]@{ Name = 'Nerd Font sample (PUA)'; Cps = @(0xF121,0xF0E7,0xF17A); Note='Пример PUA-иконок (часто будут □)' }
)

# =========================
# RUN 1: as-is
# =========================
Test-Items "RUN #1 (как есть, без изменения кодировок)" $items

# =========================
# RUN 2: temporarily set Console encoding to UTF-8 and retest
# =========================
$prevOut = [Console]::OutputEncoding
$prevIn  = [Console]::InputEncoding

try {
  Hr "Switch [Console] encodings -> UTF-8 (temporary) and retest"
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new($false)

  Write-Host ("Now [Console] OutputEnc : {0} / {1}" -f [Console]::OutputEncoding.WebName, [Console]::OutputEncoding.EncodingName)
  Write-Host ("Now [Console] InputEnc  : {0} / {1}" -f [Console]::InputEncoding.WebName,  [Console]::InputEncoding.EncodingName)

  Test-Items "RUN #2 (после переключения Output/Input Encoding на UTF-8)" $items
}
finally {
  [Console]::OutputEncoding = $prevOut
  [Console]::InputEncoding  = $prevIn
}

Hr "DONE"
Write-Host "Подсказка: запускай этот скрипт в ConHost (автономное окно) и в VS Code/WT — сравни, где что превращается в □/?."
