#region Compare calling a function against calling code
$Loop = {
  $Rand = [System.Random]::new()
  for ($i = 0; $i -lt 10000; $i++) {
    $null = $Rand.Next()
  }
}
$Func = {
  $Rand = [System.Random]::new()
  function NextRandom {
    param($rng)
    $rng.Next()
  }
  for ($i = 0; $i -lt 10000; $i++) {
    $null = NextRandom -rng $Rand
  }
}
$FuncPerf = Test-Performance -Count 10 -ScriptBlock $Func
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
$LoopPerf = Test-Performance -Count 10 -ScriptBlock $Loop
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
Get-Winner -AName "Loop" -AValue $LoopPerf.Median -BName "Function" -BValue $FuncPerf.Median
#endregion

#region Compare a Script Block against calling code
$Loop = {
  $Rand = [System.Random]::new()
  for ($i = 0; $i -lt 10000; $i++) {
    $null = $Rand.Next()
  }
}
$Block = {
  Param($rng)
  $rng.Next()
}
$BlockInLoop = {
  $Rand = [System.Random]::New()
  for ($i = 0; $i -lt 10000; $i++) {
    $null = Invoke-Command -ScriptBlock $Block -ArgumentList $Rand
  }
}
$LoopPerf = Test-Performance -Count 10 -ScriptBlock $Loop
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
$BlockPerf = Test-Performance -Count 10 -ScriptBlock $BlockInLoop
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
Get-Winner -AName "Loop" -AValue $LoopPerf.Median -BName "Script Block" -BValue $BlockPerf.Median

#endregion

$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'
Measure-Command -Expression {Write-Host "Host"; Write-Output "Output"; Write-Warning "Warning"; Write-Error "Error"; Write-Verbose "Verbose"; Write-Debug "Debug"}