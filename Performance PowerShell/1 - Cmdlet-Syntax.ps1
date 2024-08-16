#region CmdLet Choice
$WmiBlock = {
    $wmi = Get-WmiObject -Class Win32_ComputerSystem
    Remove-Variable wmi
}

$CimBlock = {
    $cim = Get-CimInstance -ClassName Win32_ComputerSystem
    Remove-Variable cim
}

$WmiPerf = Test-Performance -Count 25 -ScriptBlock $WmiBlock
$CimPerf = Test-Performance -Count 25 -ScriptBlock $CimBlock

Get-Winner -AName 'WMI' -AValue $WmiPerf.Median -BName 'CIM' -BValue $CimPerf.Median
#endregion

#region Different Cmdlets, Same Result
$W32TimeInfo = Get-Service -Name W32Time | ConvertTo-Json
$SetContent = {
    Set-Content -Path "C:\temp\SetContent.txt" -Value $W32TimeInfo -Force
}
$SetCPerf = Test-Performance -Count 5 -ScriptBlock $SetContent
$OutFile = {
    Out-File -FilePath "C:\temp\OutFile.txt" -InputObject $W32TimeInfo -Force
}
$OutFPerf = Test-Performance -Count 5 -ScriptBlock $OutFile
Get-Winner -AName "Set-Content" -AValue $SetCPerf.Median -BName "Out-File" -BValue $OutFPerf.Median
#endregion

#region Syntax Choice (Order)
$Continue = $false
$Number = 1
$Array = 1..10000 | ForEach-Object {
    [PSCustomObject]@{
        Id   = $_
        Name = "Name$_"
    }
}
#$Array = @('the','quick','fox','jumps','over','the','lazy','brown','dog')

$OrderA = {
    if ($Array.Id -contains '5555' -and '1' -eq $Number -and $Continue) {
        Write-Output "Critiera Satisfied"
    }
}
$APerf = Test-Performance -Count 10 -ScriptBlock $OrderA

$OrderB = {
    if ($Continue -and $Number -eq '1' -and $Array -contains '5555') {
        Write-Output "Criteria Satisfied"
    }
}
$BPerf = Test-Performance -Count 10 -ScriptBlock $OrderB

Get-Winner -AName "Order A" -AValue $APerf.Median -BName "Order B" -BValue $BPerf.Median

#endregion

#region Case Sensitivity
$CIM = {
    $Rabbit = 'Fluffy'
    $Dog = 'Spot'
    $Fish = 'Trout'
    $Match = $false
    if ($Rabbit -eq 'fluffy' -and $dog -eq 'SPOT' -and $Fish -eq 'TrOuT') {
        $Match = $true
    }
}
$CimPerf = Test-Performance -Count 10 -ScriptBlock $CIM
$CSM = {
    $Rabbit = 'Fluffy'
    $Dog = 'Spot'
    $Fish = 'Trout'
    $Match = $false
    if ($Rabbit -ceq 'Fluffy' -and $dog -ceq 'Spot' -and $Fish -ceq 'Trout') {
        $Match = $true
    }
}
$CsmPerf = Test-Performance -Count 10 -ScriptBlock $CSM
Get-Winner -AName "Case Insensitive" -AValue $CimPerf.Median -BName "Case Sensitive" -BValue $CsmPerf.Median
#endregion

#region loops
$Array = 1..1000
$ForEach = {
    foreach ($num in $Array) {
        if ($num -eq 999) {
            Write-Output "Found"
        }
    }
}
$FePerf = Test-Performance -Count 10 -ScriptBlock $ForEach
$FeObject = {
    $Array | ForEach-Object {
        if ($_ -eq 999) {
            Write-Output "Found"
        }
    }
}
$FeOPerf = Test-Performance -Count 10 -ScriptBlock $FeObject
Get-Winner -AName "ForEach (Operator)" -AValue $FePerf.Median -BName "ForEach (CmdLet)" -BValue $FeOPerf.Median
#endregion

#region Count Variable vs .Count
$VarCount = {
    $ObjList = [System.Collections.Generic.List[Object]]::new()
    for ($i = 0; $i -lt 10000; $i++) {
        $Obj = "" | Select-Object Id,Letter
        $Obj.Id = $i
        $Obj.Letter = [char](Get-Random -Minimum 65 -Maximum 90)
        [void]$ObjList.Add($Obj)
    }
    
    $Counter = $ObjList.Count
    for ($j = 0; $j -lt $Counter; $j++) {
        $ObjList[$j].Id++
    }
}
$PropCount = {
    $ObjList = [System.Collections.Generic.List[Object]]::new()
    for ($i = 0; $i -lt 10000; $i++) {
        $Obj = "" | Select-Object Id,Letter
        $Obj.Id = $i
        $Obj.Letter = [char](Get-Random -Minimum 65 -Maximum 90)
        [void]$ObjList.Add($Obj)
    }
    
    for ($j = 0; $j -lt $ObjList.Count; $j++) {
        $ObjList[$j].Id++
    }
}
$VarPerf = Test-Performance -Count 5 -ScriptBlock $VarCount
$PropPerf = Test-Performance -Count 5 -ScriptBlock $PropCount
Get-Winner -AName "Variable" -AValue $VarPerf.Median -BName "Property" -BValue $PropPerf.Median
#endregion

#region Array vs List
$Arr = {
    $Array = @()
    for ($i = 0; $i -lt 10000; $i++) {
        $Array += $i
    }
    $Array.Count
}
$ArrPerf = Test-Performance -Count 5 -ScriptBlock $Arr
$Lst = {
    [System.Collections.Generic.List[int]]$List = [System.Collections.Generic.List[int]]::new()
    for ($i = 0; $i -lt 10000; $i++) {
        [void]$List.Add($i)
    }
    $List.Count
}
$LstPerf = Test-Performance -Count 5 -ScriptBlock $Lst
Get-Winner -AName 'Array' -AValue  $ArrPerf.Median -BName 'List' -BValue $LstPerf.Median
#endregion

#region String Builder vs +=
$sb = {
    $String = [System.Text.StringBuilder]::new("This is ")
    for ($i = 0; $i -lt 100000; $i++) {
        $Add = [char](Get-Random -Minimum 65 -Maximum 91)
        $String.Append($Add)
    }
}
$SbPerf = Test-Performance -Count 5 -ScriptBlock $sb
$pe = {
    $String = "This is "
    for ($i = 0; $i -lt 100000; $i++) {
        $Add = [char](Get-Random -Minimum 65 -Maximum 91)
        $String += $Add
    }
}
$PePerf = Test-Performance -Count 5 -ScriptBlock $pe
Get-Winner -AName 'String Builder' -AValue $SbPerf.Median -BName 'String +=' -BValue $PePerf.Median
#endregion