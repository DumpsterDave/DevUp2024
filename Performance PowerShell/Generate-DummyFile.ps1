[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFilePath,
    [Parameter(Mandatory=$true)]
    [int]$SizeInBytes
)
$CharSet = [System.Collections.Generic.List[char]]::new()
for ($i = 33; $i -lt 127; $i++) {
    [void]$CharSet.Add([char]($i))
}
for ($i = 161; $i -lt 1025; $i++) {
    [void]$CharSet.Add([char]($i))
}
$CharSetSize = $CharSet.Count

$String = [System.Text.StringBuilder]::new()
for($b = 0; $b -lt $SizeInBytes; $b++) {
    [void]$String.Append([char](Get-Random -Minimum 0 -Maximum $CharSetSize))
}
Out-File -FilePath $OutputFilePath -Encoding utf8 -InputObject $String.ToString() -Force