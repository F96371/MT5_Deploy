# ===== MT5 全流程自动化部署 (含母本安装) =====
# 适用于阿里云香港服务器 - 直连 GitHub

# [配置区]
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaUrl = "$githubBase/智汇矩阵 V102 版本 (ssai).ex5"
$eaName = "智汇矩阵 V102 版本 (ssai).ex5"

# 1. 下载并静默安装母本
Write-Host "`n[1/4] 正在下载并静默安装 MT5 母本..." -ForegroundColor Cyan
$setupPath = "$env:TEMP\exness5setup.exe"
Invoke-WebRequest -Uri "$githubBase/exness5setup.exe" -OutFile $setupPath
Start-Process -FilePath $setupPath -ArgumentList "/path:C:\MT5_Master /auto" -Wait
Stop-Process -Name "terminal64" -Force -ErrorAction SilentlyContinue

# 2. 批量克隆与环境隔离
Write-Host "[2/4] 正在克隆 5 个独立交易环境..." -ForegroundColor Cyan
1..5 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"
    if (!(Test-Path $target)) { Copy-Item "C:\MT5_Master" $target -Recurse -Force }
}

# 3. 从云端推送 EA 策略
Write-Host "[3/4] 正在从云端推送 EA 策略..." -ForegroundColor Cyan
1..5 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $dir = "C:\MT5_$n\MQL5\Experts\"
    if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
    Invoke-WebRequest -Uri $eaUrl -OutFile "$dir\$eaName"
}

# 4. 生成桌面快捷方式并注入开机自启
Write-Host "[4/4] 正在配置自启动快捷方式..." -ForegroundColor Cyan
$Wsh = New-Object -ComObject WScript.Shell
1..5 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $lnk = "$([Environment]::GetFolderPath('Desktop'))\Account_$n.lnk"
    $sc = $Wsh.CreateShortcut($lnk)
    $sc.TargetPath = "C:\MT5_$n\terminal64.exe"
    $sc.Arguments = "/portable /skipupdate"
    $sc.WorkingDirectory = "C:\MT5_$n"
    $sc.Save()
    Copy-Item $lnk "$([Environment]::GetFolderPath('Startup'))\" -Force
}

Write-Host "`n 所有流程已完成！" -ForegroundColor Green
Write-Host "请手动登录 5 个账户并设置：" -ForegroundColor Yellow
Write-Host "  1. Ctrl+O -> Charts -> Max bars = 5000" -ForegroundColor Yellow
Write-Host "  2. Ctrl+O -> Expert Advisors -> 勾选两项" -ForegroundColor Yellow
