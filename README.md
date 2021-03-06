# sfsens
SpeedFan logfile parser on powershell for Zabbix LLD. Monitor temperature of hardware on Windows Servers or workstations.

==

Задался целью мониторить температуру и прочие данные с железных серверов под виндой.
Ничего "умнее" не придумал, чем парсить лог-файл программки SpeedFan, благо она отдает все значение в превосходной CSVшке.

## Установка.

Устанавливаем SpeedFan (если ставите не в `Program Files`, то нужно менять в скрипте путь к логфайлу, переменная `$LogFilePath`).
Включаем в нем логирование нужных параметров. Обязательно ставим разделитель точку для значений в логе.
По желанию, после настройки, можно его повесить в качестве службы, рекомендую для этого программку nssm.

В заббикс-агенте на целевой машине любым удобным способом добавляем следующие UserParameter:
```
UserParameter=sf.discovery,powershell -executionpolicy bypass -file "c:\Program Files\Zabbix Agent\sfsens.ps1" -Json
UserParameter=sf.sens[*],powershell -executionpolicy bypass -file "c:\Program Files\Zabbix Agent\sfsens.ps1" -Sens "$1"
UserParameter=sf.sfproc,powershell -executionpolicy bypass -file "c:\Program Files\Zabbix Agent\sfsens.ps1" -SFProc
```

А так же делаем параметр Timeout побольше:

`Timeout=10`

Проверьте путь, где у вас будет лежать `sfsens.ps1`.

После этого создаем правило LLD в заббиксе. Для обнаружения используем ключ `sf.discovery`, для прототипов итемов `sf.sens[MACROS]`.
Список макросов можно получить запросив у агента ключ `sf.discovery`, он выдаст возможные варианты в виде json массива.
Содержимое массива зависит от того какие сенсоры вы логируете в SpeedFan.

Вариант рабочий, но черновой. Использовать на свой страх и риск.

==

This script parse speedfan log file and return values to zabbix via LLD items.

## Installation.

Sorry for my english. :)

Install SpeedFan (if you changed default path, than you should change it in the script, `$LogFilePath` variable).
Enable log, be sure that separator for log values is set to dot.
If you want to run SpeedFan as a service, i recommend to use NSSM for it.

In zabbix-agent conf file add next UserParameters:
```
UserParameter=sf.discovery,powershell -executionpolicy bypass -file "c:\Program Files\Zabbix Agent\sfsens.ps1" -Json
UserParameter=sf.sens[*],powershell -executionpolicy bypass -file "c:\Program Files\Zabbix Agent\sfsens.ps1" -Sens "$1"
UserParameter=sf.sfproc,powershell -executionpolicy bypass -file "c:\Program Files\Zabbix Agent\sfsens.ps1" -SFProc
```

Also increase Timeout parameter:

`Timeout=10`

Check the path to sfsens.ps1 file.

After this we create LLD Discovery item in zabbix with `sf.discovery` key, and items prototype with `sf.sens[MACROS]` key.
List of MACROSes you can obtain by viewing output of `sf.discovery` key on target host.
They are depends on which sensors you logged in the SpeedFan.

Use it on your own risk. It's not final script, things can be changed, but it's works fine on my servers.
