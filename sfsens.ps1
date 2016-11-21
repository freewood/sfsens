Param([switch]$Json,[string]$Sens)

#PoSh 2.0 compatible
$PSScriptRoot = split-path -parent $MyInvocation.MyCommand.Definition

$SpeedFanFolder = "c:\Program Files (x86)\SpeedFan\"
$LogName = "SFLog"+(Get-Date -Format yyyyMMdd)+".csv"

If (!(Test-Path "$SpeedFanFolder$LogName")) {

    return "Error: SpeedFan log file not found!"
    Break

}

$header = ((Get-Content "$SpeedFanFolder\$LogName" -TotalCount 1) -creplace ("\x00","")).split("`t")

#Если указан аргумент -Json*, то отдаем в JSON массиве список сенсоров взятых из лога
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
    Break}

#Если передан аргумент -Sens "string", то ищем в логе последнее значение колонки string и отдаем
If ($Sens) {
    If (!(Test-Path $PSScriptRoot\$Sens)) {
        New-Item -path $PSScriptRoot -Name $Sens -ItemType file | Out-Null
    }

    #PoSh 3.0+ feature
    #[int]$index = $header::indexof($header,"$Sens")

    [int]$index = (0..($header.Count-1)) | Where-Object {$header[$_] -ceq "$Sens"}

    #PoSh 3.0+ feature
    #$LastRow = (Get-Content "$SpeedFanFolder$LogName" -Tail 1).split("`t")

    $LastRow = (Get-Content "$SpeedFanFolder$LogName" | Select-Object -Last 1).split("`t")
    [int]$Marker = $LastRow[0]

    If ((Get-Content "$PSScriptRoot\$Sens") -cne ($Marker)) {
        $SensResult = $LastRow[$index]
        $Marker | Out-File "$PSScriptRoot\$Sens"
        $SensResult
    }
    Break
}