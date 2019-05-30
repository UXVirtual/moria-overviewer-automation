# Requires: Tiny Task (https://www.tinytask.net/)
# Requires: Minecraft overviewer 0.13 or higher (https://overviewer.org/downloads)
# Requires: AWS CLI (https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi)



$saveDir="$env:APPDATA/.minecraft/saves/"
$overviewerDir="$PSScriptRoot\..\overviewer"
$outDir="$overviewerDir\..\out"
$stamp=(get-date).toString('yyyyMMddhhmm')
$logPath="$overviewerDir\..\logs\$stamp.log"

$stdErrLog = "$overviewerDir\..\logs\stderr.log"
$stdOutLog = "$overviewerDir\..\logs\stdout.log"

# Delete files older than 7 days
Get-ChildItem -Directory $saveDir | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-7))} | Remove-Item

# Run Tiny Task macro to open Minecraft and download latest update
$p = Start-Process "$overviewerDir\..\automation\backup-macro.exe" -NoNewWindow -PassThru -RedirectStandardOutput $stdOutLog -RedirectStandardError $stdErrLog -wait
$p.WaitForExit()
$p.ExitCode

Get-Content $stdErrLog, $stdOutLog | Out-File $logPath -Append

# Get latest Minecraft Realms backup
Get-childItem env:
$newest=Get-ChildItem -Directory $saveDir | Sort CreationTime -Descending | Select -First 1

# Set overviewer environment vars
$env:IN_DIR="$saveDir/$newest"
$env:OUT_DIR=$outDir

# Generate updated map
$p2 = Start-Process "$overviewerDir\overviewer.exe" -ArgumentList "--config=$overviewerDir\..\automation\overviewer.cfg.py" -NoNewWindow -PassThru -RedirectStandardOutput $stdOutLog -RedirectStandardError $stdErrLog -wait
$p2.WaitForExit()
$p2.ExitCode

Get-Content $stdErrLog, $stdOutLog | Out-File $logPath -Append

# Generate updated map POI
$p3 = Start-Process "$overviewerDir\overviewer.exe" -ArgumentList "--config=$overviewerDir\..\automation\overviewer.cfg.py  --genpoi --skip-players" -NoNewWindow -PassThru -RedirectStandardOutput $stdOutLog -RedirectStandardError $stdErrLog -wait
$p3.WaitForExit()
$p3.ExitCode

Get-Content $stdErrLog, $stdOutLog | Out-File $logPath -Append

# Sync to s3 bucket
$p4 = Start-Process "C:\Program Files\Amazon\AWSCLI\bin\aws.exe" -ArgumentList "s3 sync $outDir s3://moria-minecraft/map" -NoNewWindow -PassThru -RedirectStandardOutput $stdOutLog -RedirectStandardError $stdErrLog -wait
$p4.WaitForExit()
$p4.ExitCode

Get-Content $stdErrLog, $stdOutLog | Out-File $logPath -Append

Remove-Item $stdErrLog
Remove-Item $stdOutLog