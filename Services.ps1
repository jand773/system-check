Write-Host '=================================================='
Write-Host ' SYSTEM BOOT TIME' -ForegroundColor Cyan
Write-Host '=================================================='
$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$up = (Get-Date) - $boot
Write-Host ('  Last Boot: ' + $boot.ToString('yyyy-MM-dd HH:mm:ss'))
Write-Host ('  Uptime: ' + $up.Days + ' days, ' + $up.ToString('hh\:mm\:ss'))
Write-Host ''

Write-Host '=================================================='
Write-Host ' CONNECTED DRIVES' -ForegroundColor Cyan
Write-Host '=================================================='
Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object {
    $fs = $_.FileSystem
    if (-not $fs) { $fs = '-' }
    Write-Host ('  ' + $_.DriveLetter + ':  ' + $fs)
}
Write-Host ''

$services = @('SysMain', 'PcaSvc', 'DPS', 'EventLog', 'Schedule', 'Bam', 'Dusmsvc', 'Appinfo', 'CDPSvc', 'DcomLaunch', 'PlugPlay', 'wsearch')

Write-Host '=================================================='
Write-Host ' ESTADO DE SERVICIOS DEL SISTEMA' -ForegroundColor Cyan
Write-Host (' ' + (Get-Date -Format 'dddd dd/MM/yyyy HH:mm:ss'))
Write-Host '=================================================='
Write-Host ''

Write-Host ('SERVICE'.PadRight(12) + ' | ' + 'DISPLAY NAME'.PadRight(40) + ' | STATUS')
Write-Host ('-' * 66)

foreach ($name in $services) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Host ($name.PadRight(12) + ' | ' + 'No encontrado'.PadRight(40) + ' | -') -ForegroundColor DarkGray
        continue
    }
    $status = $svc.Status.ToString()
    $display = $svc.DisplayName
    if (-not $display) { $display = $name }
    if ($display.Length -gt 40) { $display = $display.Substring(0, 37) + '...' }
    $color = 'White'
    if ($status -eq 'Running') { $color = 'Green' }
    elseif ($status -eq 'Stopped') { $color = 'Red' }
    else { $color = 'Yellow' }
    Write-Host ($name.PadRight(12) + ' | ' + $display.PadRight(40) + ' | ' + $status) -ForegroundColor $color
}

Write-Host ''

Write-Host '=================================================='
Write-Host ' PAPELERA DE RECICLAJE' -ForegroundColor Cyan
Write-Host '=================================================='
$recyclePath = 'C:\$Recycle.Bin'
if (Test-Path -LiteralPath $recyclePath) {
    $recycleFiles = Get-ChildItem -LiteralPath $recyclePath -Recurse -Force -File -ErrorAction SilentlyContinue
    if ($recycleFiles) {
        $latest = $recycleFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Host ('Ultima modificacion: ' + $latest.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss'))
        Write-Host ('Archivo mas reciente: ' + $latest.Name)
        Write-Host ('Total de archivos: ' + $recycleFiles.Count)
    } else {
        Write-Host 'La papelera esta vacia.'
    }
} else {
    Write-Host 'No se encontro la carpeta de la papelera.'
}
Write-Host ''

Write-Host '=================================================='
Write-Host ' PREFETCH' -ForegroundColor Cyan
Write-Host '=================================================='
$prefetchPath = 'C:\Windows\Prefetch'
if (Test-Path -LiteralPath $prefetchPath) {
    try {
        $pfFiles = Get-ChildItem -LiteralPath $prefetchPath -Filter *.pf -Force -File -ErrorAction Stop
        if ($pfFiles) {
            $latestPf = $pfFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            Write-Host ('Cantidad de archivos .pf: ' + $pfFiles.Count)
            Write-Host ('Ultimo archivo modificado: ' + $latestPf.Name + ' - ' + $latestPf.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss'))
            $pfFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 10 | ForEach-Object {
                Write-Host ('  ' + $_.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss') + '  ' + $_.Name)
            }
        } else {
            Write-Host 'No hay archivos .pf en Prefetch.'
        }
    } catch {
        Write-Host 'Acceso denegado a Prefetch (se requiere modo administrador).'
    }
} else {
    Write-Host 'No se encontro la carpeta Prefetch.'
}
Write-Host ''

Write-Host '=================================================='
Write-Host ' REGISTRY' -ForegroundColor Cyan
Write-Host '=================================================='

function Get-RegInt {
    param([string]$Path, [string]$Name)
    try {
        return [int](Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name
    } catch {
        return $null
    }
}

function Write-Status {
    param([string]$Label, [string]$Status)
    if ($Status -eq 'Enabled' -or $Status -eq 'Available') {
        Write-Host ($Label + ': ' + $Status) -ForegroundColor Green
    } else {
        Write-Host ($Label + ': ' + $Status) -ForegroundColor Red
    }
}

$cmdVal = Get-RegInt 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' 'ProcessCreationIncludeCmdLine_Enabled'
if ($null -eq $cmdVal) { Write-Status 'CMD' 'Available' }
elseif ($cmdVal -eq 1) { Write-Status 'CMD' 'Enabled' }
else { Write-Status 'CMD' 'Disabled' }

$psVal = Get-RegInt 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' 'EnableScriptBlockLogging'
if ($null -eq $psVal) { Write-Status 'PowerShell Logging' 'Available' }
elseif ($psVal -eq 1) { Write-Status 'PowerShell Logging' 'Enabled' }
else { Write-Status 'PowerShell Logging' 'Disabled' }

$actVal = Get-RegInt 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed'
if ($null -eq $actVal) { Write-Status 'Activities Cache' 'Available' }
elseif ($actVal -eq 1) { Write-Status 'Activities Cache' 'Enabled' }
else { Write-Status 'Activities Cache' 'Disabled' }

$pfVal = Get-RegInt 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'EnablePrefetcher'
if ($null -eq $pfVal) { Write-Status 'Prefetch Enabled' 'Available' }
elseif ($pfVal -gt 0) { Write-Status 'Prefetch Enabled' 'Enabled' }
else { Write-Status 'Prefetch Enabled' 'Disabled' }

Write-Host ''

Write-Host '=================================================='
Write-Host ' Proceso finalizado.'
Write-Host '=================================================='
Read-Host 'Press any key to continue...'