#region No Runspace
$NoRunspace = {
  for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep -Seconds 1
    Write-Output "Completed $($i)"
  }
}
$NoRsPerf = Test-Performance -Count 2 -ScriptBlock $NoRunspace
#endregion

#region default runspaces
$DefaultRunspace = {
  #Setup the pool
  $RunspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
  $RunspacePool.Open()

  #Create the workers and add them to the pool
  $Spaces = [System.Collections.Generic.List[Object]]::new()
  for ($i = 0; $i -lt 10; $i++) {
    $PowerShell = [powershell]::Create()
    $PowerShell.Runspace.Name = "Runspace_$($i)"
    $PowerShell.RunspacePool = $RunspacePool
    #Add the code that actuall does stuff
    [void]$PowerShell.AddScript({
        Param(
            [string]$Param1,
            [int]$Param2
        )
        Start-Sleep -Seconds 1
        Write-Output "Runspace_$($Param2) [PID: $($pid), TID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)] has completed"  #Will return output via EndInvoke
    })
    #Create the parameter object and add it to the PowerShell object
    $Parameters = @{
        #These are passed BY COPY.  You cannot pass data back out of a runspace with normal parameters
        Param1 = "Runspace_$($i)";
        Param2 = $i;
    }
    [void]$PowerShell.AddParameters($Parameters)

    #Queue it up for processing and add the record to our list
    $Handle = $PowerShell.BeginInvoke()
    
    $temp = '' | Select-Object PowerShell,Handle
    $temp.PowerShell = $PowerShell
    $temp.handle = $Handle
    [void]$Spaces.Add($Temp)
  }

  [void]$RunspacePool.GetAvailableRunspaces()
  
  $Mem = Get-Process -Id $pid
  Write-Output "Total Consumed Memory: $($Mem.WorkingSet / 1MB)MB"
  #Wait for each one to complete and output the results.
  foreach ($rs in $Spaces) {
      $output = $rs.PowerShell.EndInvoke($rs.Handle)
      Write-Host $output -ForegroundColor Green
      $rs.PowerShell.Dispose()
  }

  $Spaces.clear()
}
$RsPerf = Test-Performance -Count 2 -ScriptBlock $DefaultRunspace
#endregion

Get-Winner -AName "No Runspace" -AValue $NoRsPerf.Median -BName "Runspaces" -BValue $RsPerf.Median


#region Constrained Runspace pt2
$Constrained = {
  $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
  $InitialSessionState.LanguageMode = 'Full'
  $InitialSessionState.ExecutionPolicy = 'Bypass'
  #Add Namespaces
  #$InitialSessionState.Assemblies.Add('System.Threading.Thread')
  $InitialSessionState.Assemblies.Add('System.Runtime')
  #$InitialSessionState.ImportPSModule('Microsoft.PowerShell.Utility')
  $RunspacePool = [runspacefactory]::CreateRunspacePool(1, 10, $InitialSessionState, $Host)
  $RunspacePool.Open()

  $Spaces = [System.Collections.Generic.List[Object]]::new()
  for ($i = 0; $i -lt 30; $i++) {
    $PowerShell = [powershell]::Create()
    $PowerShell.Runspace.Name = "Runspace_$($i)"
    $PowerShell.RunspacePool = $RunspacePool
    #Add the code that actuall does stuff
    [void]$PowerShell.AddScript({
        Param(
            [string]$Param1,
            [int]$Param2
        )
        $Rand = [Random]::New()
        for ($i = 0; $i -lt 10000; $i++) {
          $null = $Rand.Next()
        }
        Write-Output "Runspace_$($Param2) [PID: $($pid), TID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)] has completed"  #Will return output via EndInvoke
    })
    #Create the parameter object and add it to the PowerShell object
    $Parameters = @{
        #These are passed BY COPY.  You cannot pass data back out of a runspace with normal parameters
        Param1 = "Runspace_$($i)";
        Param2 = $i;
    }
    [void]$PowerShell.AddParameters($Parameters)

    #Queue it up for processing and add the record to our list
    $Handle = $PowerShell.BeginInvoke()
    
    $temp = '' | Select-Object PowerShell,Handle
    $temp.PowerShell = $PowerShell
    $temp.handle = $Handle
    [void]$Spaces.Add($Temp)
  }
  [void]$RunspacePool.GetAvailableRunspaces()

  $Mem = Get-Process -Id $pid
  Write-Output "Total Consumed Memory: $($Mem.WorkingSet / 1MB)MB"
  #Wait for each one to complete and output the results.
  foreach ($rs in $Spaces) {
      $output = $rs.PowerShell.EndInvoke($rs.Handle)
      Write-Host $output -ForegroundColor Green
      $rs.PowerShell.Dispose()
  }

  $Spaces.clear()
}
Test-Performance -Count 5 -ScriptBlock $Constrained
#endregion