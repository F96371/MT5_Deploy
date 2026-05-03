# ===== MT5 EA 防盗删除脚本 =====
# 使用 Everything 搜索并删除所有已分发的 .ex5 文件

# [配置区]
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$esPath = "$env:TEMP\es.exe"

Write-Host "`n[=== MT5 EA 防盗删除 ===]" -ForegroundColor Green

# 步骤 1：确保 Everything 命令行工具存在
if (!(Test-Path $esPath)) {
    Write-Host "`n[*] 下载 Everything 命令行工具..." -ForegroundColor Cyan
    $setupUrl = "$githubBase/Everything-1.4.1.1032.x86-Setup.exe"
    $setupPath = "$env:TEMP\es_setup.exe"
    
    Invoke-WebRequest -Uri $setupUrl -OutFile $setupPath
    
    # 静默安装并提取 es.exe
    Start-Process -FilePath $setupPath -ArgumentList "/silent /install=$env:TEMP" -Wait
    Copy-Item "$env:TEMP\es.exe" $esPath -Force
    
    Write-Host "[+] Everything 命令行工具已安装" -ForegroundColor Green
}

# 步骤 2：搜索所有 MT5 目录下的 .ex5 文件
Write-Host "`n[*] 正在搜索 .ex5 文件..." -ForegroundColor Cyan

# 使用 Everything 搜索
$searchResults = & $esPath -regex "C:\\MT5_\d{2}\\MQL5\\Experts\\.*\.ex5$" -o 100

if ($searchResults.Count -eq 0) {
    Write-Host "[-] 未找到任何 .ex5 文件" -ForegroundColor Yellow
    exit 0
}

Write-Host "[+] 找到 $($searchResults.Count) 个文件：" -ForegroundColor Green
$searchResults | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

# 步骤 3：删除所有找到的文件
Write-Host "`n[*] 开始删除..." -ForegroundColor Cyan
$deletedCount = 0
$failCount = 0

foreach ($file in $searchResults) {
    try {
        Remove-Item $file -Force -ErrorAction Stop
        Write-Host "  [x] 已删除: $file" -ForegroundColor Yellow
        $deletedCount++
    } catch {
        Write-Host "  [!] 删除失败: $file : $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n[+] 删除完成：已删除 $deletedCount 个文件，失败 $failCount 个" -ForegroundColor Green
