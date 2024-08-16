#region Pipeline vs Long-Form
$Pipeline = {
    $RunningServices = Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name
    Write-Output $RunningServices.Count
    Remove-Variable RunningServices
}
$PipePerf = Test-Performance -Count 10 -ScriptBlock $Pipeline
$LongForm = {
    $AllServices = Get-Service
    $RunningServices = [System.Collections.Generic.List[Object]]::New()
    foreach ($svc in $AllServices) {
        if ($svc.Status -eq 'Running') {
            [void]$RunningServices.Add($svc.Name)
        }
    }
    Write-Output $RunningServices.Count
    Remove-Variable RunningServices
}
$LongPerf = Test-Performance -Count 10 -ScriptBlock $LongForm
Get-Winner -AName "Pipeline" -AValue $PipePerf.Median -BName "Long Form" -BValue $LongPerf.Median

Get-Winner -AName "Pipeline" -AValue $PipePerf.Occurrence[0] -BName "Long Form" -BValue $LongPerf.Occurrence[0]

$PipePerf

$LongPerf
#endregion

#region Pipeline streams
function StreamOutput {
    [CmdletBinding()]
    Param()
    begin {
        $Delay = @(100,200,300,400,500,600,700,800,900,1000)
    }
    process {
        for ($i = 0; $i -lt 10; $i++) {
            Start-Sleep -Milliseconds $Delay[$i]
            Write-Output $i
        }
    }
}
function OutputRandomColor {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Value
    )
    begin {
        $r = Get-Random -Minimum 0 -Maximum 255
        $g = Get-Random -Minimum 0 -Maximum 255
        $b = Get-Random -Minimum 0 -Maximum 255
    }
    process {
        Write-Output "`e[38;2;$($r);$($g);$($b)m$($Value)"
    }
}
function StopAtFive {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Value
    )
    begin {
        $List = [System.Collections.Generic.List[string]]::new()
    }
    process {
        if ($Value -le '5') {
            [void]$List.Add($Value)
        }
        if ($Value -eq '5') {
            return $List
        }
    } 
}
$Pipeline = {
    StreamOutput | StopAtFive | OutputRandomColor
}
$AsCode = {
    $Delay = @(100,200,300,400,500,600,700,800,900,1000)
    $List = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds $Delay[$i]
        [void]$List.Add($i)
        if ($i -ge 5) {
            break
        }
    }
    $List | OutputRandomColor
}
$CodePerf = Test-Performance -Count 5 -ScriptBlock $AsCode
$PipePerf = Test-Performance -Count 5 -ScriptBlock $Pipeline
Get-Winner -AName "Pipeline" -AValue $PipePerf.Median -BName "Code" -BValue $CodePerf.Median

$CodePerf

$PipePerf
#endregion