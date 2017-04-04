<#
.SYNOPSIS
SpeedFan log file parser.

.DESCRIPTION
Generate JSON with selected sensors and return current value for desired sensor

.EXAMPLE
.\sfsens.ps1 -SFProc
This will return "1" if speedfan.exe process exist, otherwise it will return "0"

.EXAMPLE
.\sfsens.ps1 -Json
This will return JSON array with all sensors logged by SpeedFan

.EXAMPLE
.\sfsens.ps1 -Sens "SensorName"
This will return current value for "SensorName"

.LINK
https://github.com/freewood/sfsens
#>

Param( [switch]$SFProc, [switch]$Json, [string]$Sens )

$PSScriptRoot = split-path -parent $MyInvocation.MyCommand.Definition

If ($PSBoundParameters.Count -ne "1") {
    Write-Host "Error: Use only one argument. View 'Get-Help .\sfsens.ps1 -Examples'"
    Exit
}

If (((Get-WmiObject Win32_OperatingSystem).OSArchitecture) -like "64*") {
    $LogFilePath = ${env:ProgramFiles(x86)}+"\SpeedFan\"+"SFLog"+(Get-Date -Format yyyyMMdd)+".csv"
}
Else {
    $LogFilePath = ${env:ProgramFiles}+"\SpeedFan\"+"SFLog"+(Get-Date -Format yyyyMMdd)+".csv"
}

If (!(Test-Path "$LogFilePath")) {
    Write-Output "Error: SpeedFan log file not found!"
    Exit
}

If ($SFProc) {
    $sfprocess = Get-Process speedfan -ErrorAction SilentlyContinue
    If (-Not $sfprocess) {
        Write-Output "0"
        Exit
    }
    Write-Output "1"
    Exit
}

#Some headers have "nul" symbol at the end, we cut it and make array of headers
$header = ((Get-Content "$LogFilePath" -TotalCount 1) -creplace ("\x00","")).split("`t")

If ($Json) {

    $Voltages = "VTT","VDIMM AB","VDIMM CD","VDIMM EFGH","+1.5 V","3.3V","+3.3VSB","5V","+5VSB","12V","VBAT","Vcore","AVcc","AVCC","3Vcc","3Vsb","Vtt","+12V","3.3VCC","VDIMM","5VCC","-12V","VSB"

    $header = $header[1..($header.Length-1)]
    [string]$JsonResult = ""
    
    $header | ForEach-Object {
            $comma = ","
            If ($_ -ceq ($header | Select-Object -Last 1)) {
                $comma = ""
            }

            If ($_ -cMatch "^Core [0-9]+$|^CPU[0-9]+ Temp$|^CPU$") {
                $JsonResult += ("`t{`n`t`t`"{#SENSCPU}`":`""+$_+"`"`n`t}$comma`n")
                }

            ElseIf ($_ -cMatch "^HD[0-9]$") {
                $JsonResult += ("`t{`n`t`t`"{#SENSHDD}`":`""+$_+"`"`n`t}$comma`n")
                }

            ElseIf ($_ -cMatch "^FAN\s*[0-9|A-Z]$|^Sys Fan$|^CPU[0-9]* Fan$|^Chassis[0-9]$|^Aux[0-9]* Fan$") {
                $JsonResult += ("`t{`n`t`t`"{#SENSFAN}`":`""+$_+"`"`n`t}$comma`n")
                }

            ElseIf ($_ -cMatch "^P[0-9]-DIMM[A-Z][0-9] TEMP$") {
                $JsonResult += ("`t{`n`t`t`"{#SENSRAM}`":`""+$_+"`"`n`t}$comma`n")
                }

            ElseIf (($_ -cMatch "^CPU[0-9] (Vcore|VSA)$|^VIN[0-9]$") -or ($Voltages -contains $_)) {
                $JsonResult += ("`t{`n`t`t`"{#SENSVT}`":`""+$_+"`"`n`t}$comma`n")
                }

            ElseIf ($_ -cMatch "^(System|Peripheral|PCH) Temp$|^System$|^Temp[0-9]$|^GPU$|^AUX$|^SMIOVT[0-9]$") {
                $JsonResult += ("`t{`n`t`t`"{#SENSYST}`":`""+$_+"`"`n`t}$comma`n")
                }

            Else {
                $JsonResult += ("`t{`n`t`t`"{#SENS}`":`""+$_+"`"`n`t}$comma`n")
                }
            }

    $JsonResult = "{`r`n"+"`t`"data`":[`n"+$JsonResult+"`t]`n"+"}`n"
    $JsonResult
    Exit
}


If ($Sens) {

    $LWTimeSec = (((Get-Date) - (Get-ChildItem $LogFilePath).LastWriteTime)).TotalSeconds

    If ($LWTimeSec -gt 5) {
        Write-Host "Error: SpeedFan log outdated!"
        Exit
    }

    [int]$index = (0..($header.Count-1)) | Where-Object {$header[$_] -ceq "$Sens"}

    If ($index -ne 0) {
        $LastRow = (Get-Content "$LogFilePath" | Select-Object -Last 1).split("`t")
        $LastRow[$index]
    }

    Else {
        Write-Host "Error: Can't find requested sensor!"
    }

    Exit
}
