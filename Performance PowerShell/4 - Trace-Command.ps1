$ErrorActionPreference = 'SilentlyContinue'
$BaselineCode = {
  $Services = Get-Service
  foreach ($svc in $Services) {
    if ($svc.Status -eq 'running' -and $svc.StartType -eq 'automatic') {
      Write-Output $svc.Name
    }
  }
}
$OptimizedCode = {
  $Services = Get-Service
  foreach ($svc in $Services) {
    if ($svc.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running -and $svc.StartType -eq [System.ServiceProcess.ServiceStartMode]::Automatic) {
      Write-Output $svc.Name
    }
  }
}
$BasePerf = Test-Performance -Count 5 -ScriptBlock $BaselineCode
$OptPerf = Test-Performance -Count 5 -ScriptBlock $OptimizedCode
Get-Winner -AName "Baseline" -AValue $BasePerf.Median -BName "Optimized" -BValue $OptPerf.Median


Trace-Command -Name TypeConversion -ListenerOption Timestamp -Expression $BaselineCode -PSHost
Trace-Command -Name TypeConversion -ListenerOption Timestamp -Expression $OptimizedCode -PSHost