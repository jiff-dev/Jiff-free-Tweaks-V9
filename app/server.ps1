<#
  Jiff Tweaks V9 - local app server
  Serves the UI on 127.0.0.1 and runs engine actions. Nothing leaves this PC.

  Security model
    - listens on loopback only
    - every request needs the per-launch token (cookie, SameSite=Strict)
    - Host / Origin / Sec-Fetch-Site are checked (blocks other websites and DNS rebinding)
    - actions are checked against a fixed list before anything is executed
#>
param(
  [switch]$NoBrowser,
  [int]$Port = 47873
)

$ErrorActionPreference = 'Stop'
$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UiDir  = Join-Path $AppDir 'ui'
$IsWin  = ($env:OS -eq 'Windows_NT')

if ($env:JT_ROOT)   { $Root = $env:JT_ROOT }   else { $Root = Join-Path $env:SystemDrive 'JiffTweaks' }
if ($env:JT_ENGINE) { $Engine = $env:JT_ENGINE } else { $Engine = Join-Path (Split-Path -Parent $AppDir) 'engine\Jiff_Tweaks_V9.bat' }
$LogDir  = Join-Path $Root 'logs'
$OrigDir = Join-Path $Root 'original'
$Version = '9.0'

New-Item -ItemType Directory -Force -Path $Root, $LogDir | Out-Null

# anything unexpected is written to a file, because the console window is hidden
trap {
  try { ('[{0}] {1}' -f (Get-Date), $_.Exception.Message) | Add-Content -Path (Join-Path $LogDir 'app_error.log') } catch {}
  break
}

# ---------------------------------------------------------------- allowed actions
$Actions = @(
  'apply_full','reg_all','reg_system','reg_gaming','reg_input_ui','reg_priority',
  'svc_basic','svc_standard','svc_advanced','svc_xbox','tasks_disable',
  'net_all','net_global','net_interfaces','nic_tweaks','net_reset',
  'power_plan','power_delete_others','devpower','bcd_timer','privacy',
  'debloat_curated','debloat_extended','debloat_onedrive',
  'gpu_auto','nvidia_all','amd_all',
  'mitigations_off','defender_off','ntfs_tweaks','memcomp_off',
  'branding','restore_all','restore_services','restore_tasks','restore_registry','restore_power','forget_originals'
)

# ---------------------------------------------------------------- helpers
function New-Token {
  $b = New-Object byte[] 24
  $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
  $rng.GetBytes($b); $rng.Dispose()
  return (($b | ForEach-Object { $_.ToString('x2') }) -join '')
}

function Test-Admin {
  if (-not $IsWin) { return $true }
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Read-Lines([string]$path, [int]$skip) {
  # reads a file that another process is still writing to
  if (-not (Test-Path -LiteralPath $path)) { return @() }
  $fs = $null; $sr = $null
  try {
    $fs = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    $sr = New-Object IO.StreamReader($fs, [Text.Encoding]::Default)
    $all = New-Object Collections.Generic.List[string]
    while ($null -ne ($l = $sr.ReadLine())) { $all.Add($l) }
    if ($skip -gt 0) {
      if ($skip -ge $all.Count) { return @() }
      return $all.GetRange($skip, $all.Count - $skip).ToArray()
    }
    return $all.ToArray()
  } catch { return @() }
  finally { if ($sr) { $sr.Dispose() } elseif ($fs) { $fs.Dispose() } }
}

function Count-Files([string]$dir, [string]$filter) {
  if (-not (Test-Path -LiteralPath $dir)) { return 0 }
  return @(Get-ChildItem -LiteralPath $dir -Filter $filter -File -ErrorAction SilentlyContinue).Count
}

function Count-FileLines([string]$file) {
  if (-not (Test-Path -LiteralPath $file)) { return 0 }
  return @(Get-Content -LiteralPath $file -ErrorAction SilentlyContinue | Where-Object { $_ -and $_.Trim() }).Count
}

# ---------------------------------------------------------------- system info (cached)
$script:Sys = $null
function Get-SysInfo {
  if ($script:Sys) { return $script:Sys }
  if (-not $IsWin) {
    $script:Sys = @{ os = 'Windows 11 Pro'; version = '23H2'; build = '22631'; cpu = 'Intel Core i7-12700K'; cores = 12; gpu = @('NVIDIA GeForce RTX 3060'); gpuVendor = 'nvidia'
                     ramGb = 32; diskFreeGb = 412; diskTotalGb = 931; plan = 'Balanced'; host = 'JIFF-PC'; admin = $true }
    return $script:Sys
  }
  $s = @{ os = 'Windows'; version = ''; build = '0'; cpu = 'Unknown'; cores = 0; gpu = @(); gpuVendor = 'other'; ramGb = 0; diskFreeGb = 0; diskTotalGb = 0; plan = ''; host = $env:COMPUTERNAME; admin = (Test-Admin) }
  try {
    $os = Get-CimInstance Win32_OperatingSystem
    $s.os = ($os.Caption -replace '^Microsoft\s+', '')
    $s.build = [string]$os.BuildNumber
    $s.ramGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 0)
    $s.version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).DisplayVersion
  } catch {}
  try { $c = Get-CimInstance Win32_Processor | Select-Object -First 1; $s.cpu = ($c.Name -replace '\s+', ' ').Trim(); $s.cores = [int]$c.NumberOfLogicalProcessors } catch {}
  try {
    $g = @(Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name })
    $s.gpu = $g
    $j = ($g -join ' ').ToLower()
    if ($j -match 'nvidia|geforce|quadro') { $s.gpuVendor = 'nvidia' } elseif ($j -match 'amd|radeon') { $s.gpuVendor = 'amd' } elseif ($j -match 'intel') { $s.gpuVendor = 'intel' }
  } catch {}
  try {
    $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='" + $env:SystemDrive + "'")
    $s.diskFreeGb = [math]::Round($d.FreeSpace / 1GB, 0); $s.diskTotalGb = [math]::Round($d.Size / 1GB, 0)
  } catch {}
  $script:Sys = $s
  return $s
}

function Get-ActivePlan {
  if (-not $IsWin) { return 'JiffOS Ultimate' }
  try {
    $t = (& powercfg /getactivescheme 2>$null) -join ' '
    if ($t -match '\(([^)]+)\)') { return $Matches[1] }
  } catch {}
  return ''
}

$script:CpuSeed = 30
function Get-Metrics {
  if (-not $IsWin) {
    $script:CpuSeed = [math]::Max(4, [math]::Min(96, $script:CpuSeed + (Get-Random -Minimum -9 -Maximum 10)))
    return @{ cpu = $script:CpuSeed; ram = 41 + (Get-Random -Minimum 0 -Maximum 4); uptimeSec = 93844; plan = 'JiffOS Ultimate' }
  }
  $cpu = 0; $ram = 0; $up = 0
  try {
    $cpu = [int]((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average)
    $os = Get-CimInstance Win32_OperatingSystem
    $ram = [int](100 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize * 100))
    $up = [int]((Get-Date) - $os.LastBootUpTime).TotalSeconds
  } catch {}
  return @{ cpu = $cpu; ram = $ram; uptimeSec = $up; plan = (Get-ActivePlan) }
}

function Get-Backup {
  $svc  = Count-Files (Join-Path $OrigDir 'svc') '*.txt'
  $keys = Count-Files (Join-Path $OrigDir 'reg') '*.reg'
  $vals = Count-FileLines (Join-Path $OrigDir 'created.txt')
  $task = Count-FileLines (Join-Path $OrigDir 'tasks.txt')
  $plan = Count-Files $OrigDir 'plan_*.pow'
  return @{ services = $svc; regKeys = $keys; regValues = $vals; tasks = $task; plans = $plan
            hasBaseline = (($svc + $keys + $task + $plan) -gt 0) }
}

# ---------------------------------------------------------------- engine runs
$script:Run = $null
$script:LastRun = $null

function Start-Run([string]$action) {
  $id  = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + $action
  $log = Join-Path $LogDir ('gui_' + $id + '.log')
  $out = Join-Path $LogDir ('gui_' + $id + '.out')
  $psi = New-Object Diagnostics.ProcessStartInfo
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  if ($IsWin) {
    $psi.FileName = $env:ComSpec
    $psi.Arguments = '/c ""' + $Engine + '" /gui ' + $action + ' "' + $log + '" > "' + $out + '" 2>&1"'
  } else {
    # non-Windows is only used for development tests
    $psi.FileName = '/bin/bash'
    [void]$psi.ArgumentList.Add('-c')
    [void]$psi.ArgumentList.Add('"' + $Engine + '" ' + $action + ' "' + $log + '" > "' + $out + '" 2>&1')
  }
  $proc = [Diagnostics.Process]::Start($psi)
  $script:Run = @{ id = $id; action = $action; proc = $proc; log = $log; out = $out; started = (Get-Date); cancelled = $false }
  return $id
}

function Get-RunStatus($run) {
  if ($null -eq $run) { return 'idle' }
  if (-not $run.proc.HasExited) { return 'running' }
  if ($run.cancelled) { return 'cancelled' }
  $tail = Read-Lines $run.log 0
  $done = $false
  foreach ($l in $tail) { if ($l -match '\[DONE\]') { $done = $true } }
  if ($run.proc.ExitCode -eq 5) { return 'noadmin' }
  if ($done -and $run.proc.ExitCode -eq 0) { return 'done' }
  return 'failed'
}

function Get-Summary($run) {
  $res = @()
  foreach ($l in (Read-Lines $run.out 0)) {
    $t = $l.Trim()
    if (-not $t) { continue }
    if ($t -match '^\.+$') { continue }
    if ($t -match '^\[\s*\d+/\d+\]') { continue }
    if ($t -match '^Done\. Log:') { continue }
    $res += $t.TrimStart('.').Trim()
  }
  return @($res | Select-Object -Last 8)
}

# ---------------------------------------------------------------- http plumbing
$MIME = @{ '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css; charset=utf-8'; '.js' = 'application/javascript; charset=utf-8'
           '.svg' = 'image/svg+xml'; '.png' = 'image/png'; '.ico' = 'image/x-icon'; '.json' = 'application/json; charset=utf-8'; '.woff2' = 'font/woff2' }

function Send-Bytes($ctx, [byte[]]$bytes, [string]$type, [int]$status = 200) {
  $r = $ctx.Response
  $r.StatusCode = $status
  $r.ContentType = $type
  $r.Headers['Cache-Control'] = 'no-store'
  $r.Headers['X-Content-Type-Options'] = 'nosniff'
  $r.Headers['Referrer-Policy'] = 'no-referrer'
  $r.ContentLength64 = $bytes.Length
  $r.OutputStream.Write($bytes, 0, $bytes.Length)
  $r.OutputStream.Close()
}

function Send-Json($ctx, $obj, [int]$status = 200) {
  $json = ConvertTo-Json -InputObject $obj -Depth 8 -Compress
  Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes($json)) 'application/json; charset=utf-8' $status
}

function Send-Err($ctx, [int]$status, [string]$msg) { Send-Json $ctx @{ error = $msg } $status }

function Read-Body($ctx) {
  $sr = New-Object IO.StreamReader($ctx.Request.InputStream, [Text.Encoding]::UTF8)
  $t = $sr.ReadToEnd(); $sr.Dispose()
  if (-not $t) { return $null }
  try { return ($t | ConvertFrom-Json) } catch { return $null }
}

function Get-Cookie($req, [string]$name) {
  $c = $req.Cookies[$name]
  if ($c) { return $c.Value }
  return $null
}

# ---------------------------------------------------------------- listener
$Token = New-Token
$listener = $null
$boundPort = 0
foreach ($p in @($Port, 0)) {
  $try = $p
  if ($try -eq 0) { $try = Get-Random -Minimum 49200 -Maximum 65000 }
  try {
    $l = New-Object Net.HttpListener
    $l.Prefixes.Add("http://127.0.0.1:$try/")
    $l.Start()
    $listener = $l; $boundPort = $try; break
  } catch { }
}
if (-not $listener) { Write-Error 'Could not open a local port.'; exit 1 }

$Origin = "http://127.0.0.1:$boundPort"
$HostOk = @("127.0.0.1:$boundPort", "localhost:$boundPort")
$Url = "$Origin/?t=$Token"
if ($env:JT_PRINT_URL) { Write-Output $Url }

# ---------------------------------------------------------------- browser
function Start-Browser([string]$url) {
  if (-not $IsWin) { return }
  $cands = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
  )
  $exe = $cands | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
  if ($exe) {
    $prof = Join-Path $Root 'app-profile'
    $argList = @("--app=$url", "--user-data-dir=`"$prof`"", '--window-size=1280,820', '--no-first-run', '--no-default-browser-check', '--disable-sync', '--disable-features=Translate,msEdgeShopping')
    Start-Process -FilePath $exe -ArgumentList $argList | Out-Null
  } else {
    Start-Process $url | Out-Null
  }
}
if (-not $NoBrowser) { Start-Browser $Url }

# ---------------------------------------------------------------- main loop
$lastPing = Get-Date
$everPinged = $false
$byeAt = $null
$started = Get-Date
$running = $true

try {
  while ($running) {
    $task = $listener.GetContextAsync()
    while (-not $task.Wait(500)) {
      $now = Get-Date
      $busy = ($script:Run -and -not $script:Run.proc.HasExited)
      if (-not $busy) {
        if ($byeAt -and (($now - $byeAt).TotalSeconds -gt 2.5)) { $running = $false; break }
        if (-not $everPinged -and (($now - $started).TotalSeconds -gt 90)) { $running = $false; break }
        if ($everPinged -and (($now - $lastPing).TotalSeconds -gt 240)) { $running = $false; break }
      }
    }
    if (-not $running) { break }
    $ctx = $task.Result
    $req = $ctx.Request
    try {
      $path = $req.Url.AbsolutePath

      # ---- host / origin / fetch-site checks
      if ($HostOk -notcontains $req.Headers['Host']) { Send-Err $ctx 403 'bad host'; continue }
      $isPost = ($req.HttpMethod -eq 'POST')
      $orig = $req.Headers['Origin']
      if ($orig -and $orig -ne $Origin) { Send-Err $ctx 403 'bad origin'; continue }
      $sfs = $req.Headers['Sec-Fetch-Site']
      if ($sfs -and @('same-origin', 'none') -notcontains $sfs) { Send-Err $ctx 403 'bad site'; continue }

      # ---- token handshake: first load carries ?t=TOKEN and sets the cookie
      $qt = $req.QueryString['t']
      if ($qt -and $qt -eq $Token -and $path -eq '/') {
        $ctx.Response.Headers.Add('Set-Cookie', "jt=$Token; Path=/; HttpOnly; SameSite=Strict")
        $ctx.Response.Redirect('/')
        $ctx.Response.Close()
        continue
      }
      if ((Get-Cookie $req 'jt') -ne $Token) { Send-Err $ctx 401 'unauthorized'; continue }

      # ---- API
      if ($path.StartsWith('/api/')) {
        switch ($path) {
          '/api/ping' {
            $lastPing = Get-Date; $everPinged = $true; $byeAt = $null
            Send-Json $ctx @{ ok = $true }
          }
          '/api/bye' {
            $byeAt = Get-Date
            Send-Json $ctx @{ ok = $true }
          }
          '/api/state' {
            $sys = Get-SysInfo
            $runInfo = $null
            if ($script:Run) { $runInfo = @{ id = $script:Run.id; action = $script:Run.action; status = (Get-RunStatus $script:Run) } }
            Send-Json $ctx @{
              version = $Version; admin = (Test-Admin); engine = (Test-Path -LiteralPath $Engine)
              sys = $sys; backup = (Get-Backup); run = $runInfo; actions = $Actions
            }
          }
          '/api/metrics' { Send-Json $ctx (Get-Metrics) }
          '/api/run' {
            if ($isPost) {
              $b = Read-Body $ctx
              $a = ''
              if ($b -and $b.action) { $a = [string]$b.action }
              if ($a -notmatch '^[a-z0-9_]+$' -or $Actions -notcontains $a) { Send-Err $ctx 400 'unknown action'; continue }
              if ($script:Run -and -not $script:Run.proc.HasExited) { Send-Err $ctx 409 'another action is running'; continue }
              if (-not (Test-Path -LiteralPath $Engine)) { Send-Err $ctx 500 'engine not found'; continue }
              $id = Start-Run $a
              Send-Json $ctx @{ id = $id; action = $a }
            } else {
              $id = $req.QueryString['id']
              $from = 0; [void][int]::TryParse([string]$req.QueryString['from'], [ref]$from)
              $r = $script:Run
              if (-not $r -or $r.id -ne $id) { Send-Err $ctx 404 'no such run'; continue }
              $status = Get-RunStatus $r
              $lines = @(Read-Lines $r.log $from)
              $res = @{ id = $r.id; action = $r.action; status = $status; lines = $lines; next = ($from + $lines.Count)
                        elapsed = [int]((Get-Date) - $r.started).TotalSeconds }
              if ($status -ne 'running') { $res.summary = @(Get-Summary $r); $res.exit = $r.proc.ExitCode }
              Send-Json $ctx $res
            }
          }
          '/api/cancel' {
            if (-not $isPost) { Send-Err $ctx 405 'POST only'; continue }
            $r = $script:Run
            if ($r -and -not $r.proc.HasExited) {
              $r.cancelled = $true
              if ($IsWin) { & taskkill.exe /PID $r.proc.Id /T /F 2>$null | Out-Null } else { try { $r.proc.Kill() } catch {} }
            }
            Send-Json $ctx @{ ok = $true }
          }
          '/api/logs' {
            $items = @(Get-ChildItem -LiteralPath $LogDir -Filter '*.log' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 40 | ForEach-Object {
              @{ name = $_.Name; size = $_.Length; time = $_.LastWriteTime.ToString('s') } })
            Send-Json $ctx @{ logs = $items }
          }
          '/api/log' {
            $n = [string]$req.QueryString['name']
            if ($n -notmatch '^[A-Za-z0-9_.-]+\.log$') { Send-Err $ctx 400 'bad name'; continue }
            $f = Join-Path $LogDir $n
            if (-not (Test-Path -LiteralPath $f)) { Send-Err $ctx 404 'not found'; continue }
            $all = @(Read-Lines $f 0)
            if ($all.Count -gt 3000) { $all = $all[($all.Count - 3000)..($all.Count - 1)] }
            Send-Json $ctx @{ name = $n; lines = $all }
          }
          '/api/reboot' {
            if (-not $isPost) { Send-Err $ctx 405 'POST only'; continue }
            if ($IsWin) { & shutdown.exe /r /t 8 /c 'Jiff Tweaks V9' | Out-Null }
            Send-Json $ctx @{ ok = $true }
          }
          '/api/quit' {
            if (-not $isPost) { Send-Err $ctx 405 'POST only'; continue }
            Send-Json $ctx @{ ok = $true }
            $running = $false
          }
          default { Send-Err $ctx 404 'not found' }
        }
        continue
      }

      # ---- static files
      if ($path -eq '/') { $path = '/index.html' }
      $rel = $path.TrimStart('/') -replace '/', [IO.Path]::DirectorySeparatorChar
      $full = [IO.Path]::GetFullPath((Join-Path $UiDir $rel))
      $uiFull = [IO.Path]::GetFullPath($UiDir)
      if (-not $full.StartsWith($uiFull) -or -not (Test-Path -LiteralPath $full -PathType Leaf)) { Send-Err $ctx 404 'not found'; continue }
      $ext = [IO.Path]::GetExtension($full).ToLower()
      $type = $MIME[$ext]
      if (-not $type) { $type = 'application/octet-stream' }
      if ($ext -eq '.html') {
        $ctx.Response.Headers['Content-Security-Policy'] = "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"
      }
      Send-Bytes $ctx ([IO.File]::ReadAllBytes($full)) $type
    }
    catch {
      try { Send-Err $ctx 500 'server error' } catch {}
    }
  }
}
finally {
  try { $listener.Stop(); $listener.Close() } catch {}
  if ($script:Run -and -not $script:Run.proc.HasExited) {
    try { if ($IsWin) { & taskkill.exe /PID $script:Run.proc.Id /T /F 2>$null | Out-Null } else { $script:Run.proc.Kill() } } catch {}
  }
}
