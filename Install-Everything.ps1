# ===== Everything 自动安装脚本 =====
# 自动下载并安装 Everything 命令行工具

# [配置区]
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$setupUrl = "$githubBase/Everything-1.4.1.1032.x86-Setup.exe"
$setupPath = "$env:TEMP\es_setup.exe"
$esPath = "$env:TEMP\es.exe"

Write-Host "`n[=== Everything 自动安装 ===]" -ForegroundColor Green

# 检查是否已安装
if (Test-Path $esPath) {
    Write-Host "[*] Everything 命令行工具已存在：$esPath" -ForegroundColor Yellow
    Write-Host "[*] 如需重新安装，请先删除该文件" -ForegroundColor Yellow
    exit 0
}

# 下载安装包
Write-Host "`n[*] 下载 Everything 安装包..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $setupUrl -OutFile $setupPath
Write-Host "[+] 下载完成" -ForegroundColor Green

# 静默安装
Write-Host "`n[*] 静默安装..." -ForegroundColor Cyan
Start-Process -FilePath $setupPath -ArgumentList "/silent /install=$env:TEMP" -Wait
Write-Host "[+] 安装完成" -ForegroundColor Green

# 验证安装
if (Test-Path $esPath) {
    Write-Host "`n[+] Everything 命令行工具已安装到：$esPath" -ForegroundColor Green
    Write-Host "[*] 使用方法：& `"$esPath`" -search `".ex5`"" -ForegroundColor Gray
} else {
    Write-Host "`n[-] 安装失败，请检查日志" -ForegroundColor Red
}
