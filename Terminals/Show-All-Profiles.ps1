# ════════════════════════════════════════════════════════════════
# СКРИПТ: Show-All-Profiles.ps1
# Показывает ВСЕ профили PowerShell
# ════════════════════════════════════════════════════════════════

Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ВСЕ ПРОФИЛИ POWERSHELL                                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$profiles = @(
    @{
        Name = "AllUsersAllHosts"
        Desc = "Для ВСЕХ пользователей, ВСЕХ хостов (pwsh, ISE, VSCode)"
        Path = $PROFILE.AllUsersAllHosts
        Scope = "Машина"
    },
    @{
        Name = "AllUsersCurrentHost"
        Desc = "Для ВСЕХ пользователей, только текущий хост (pwsh.exe)"
        Path = $PROFILE.AllUsersCurrentHost
        Scope = "Машина"
    },
    @{
        Name = "CurrentUserAllHosts"
        Desc = "Для текущего пользователя, ВСЕХ хостов"
        Path = $PROFILE.CurrentUserAllHosts
        Scope = "Пользователь"
    },
    @{
        Name = "CurrentUserCurrentHost"
        Desc = "Для текущего пользователя, только текущий хост (ИСПОЛЬЗУЕТСЯ ЧАЩЕ ВСЕГО)"
        Path = $PROFILE.CurrentUserCurrentHost
        Scope = "Пользователь"
    }
)

foreach ($prof in $profiles) {
    $exists = Test-Path $prof.Path
    
    Write-Host "📋 $($prof.Name)" -ForegroundColor $(if ($exists) { 'Green' } else { 'Gray' })
    Write-Host "   $($prof.Desc)" -ForegroundColor White
    Write-Host "   Область: $($prof.Scope)" -ForegroundColor DarkGray
    Write-Host "   Путь: $($prof.Path)" -ForegroundColor DarkGray
    
    if ($exists) {
        $size = [Math]::Round((Get-Item $prof.Path).Length / 1KB, 2)
        $modified = (Get-Item $prof.Path).LastWriteTime
        Write-Host "   ✅ Существует ($size KB, изменен $modified)" -ForegroundColor Green
    } else {
        Write-Host "   ⚪ Не существует" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "`n💡 Что означает `$PROFILE без уточнения?" -ForegroundColor Yellow
Write-Host "   `$PROFILE = `$PROFILE.CurrentUserCurrentHost" -ForegroundColor Cyan
Write-Host "   Путь: $PROFILE`n" -ForegroundColor Gray
