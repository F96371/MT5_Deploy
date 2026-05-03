# ===== MT5 EA 自动部署 + 防盗清理脚本 =====
# 功能：分发 .ex5 → 等待加载 → 删除源文件（防盗）
# 依赖：Everything 命令行工具（es.exe）

# [配置区]
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaUrl = "$githubBase/智汇矩阵V102版本(ssai).ex5"
$eaName = "智汇矩阵V102版本(ssai).ex5"
$instances = 1..5
$loadWaitSeconds = 10  # 等待 MT5 加载的时间（秒）

# [检查 Everything 命令行工具]
$esPath = "$env:TEMP\es.exe"
if (!(Test-Path $esPath)) {
    Write-Host "[*] 下载 Everything 命令行工具..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "$githubBase/Everything-1.4.1.1032.x86-Setup.exe" -OutFile "$env:TEMP\es_setup.exe"
    # 静默安装并提取 es.exe
    Start-Process -FilePath "$env:TEMP\es_setup.exe" -ArgumentList "/silent /install=$env:TEMP" -Wait
    Copy-Item "$env:TEMP\es.exe" $esPath -Force
}

Write-Host "`n[=== MT5 EA 自动部署 + 防盗清理 ===]" -ForegroundColor Green

# [主循环]
while ($true) {
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] 开始新一轮分发..." -ForegroundColor Cyan

    # 步骤 1：分发 .ex5 到各实例
    foreach ($n in $instances) {
        $num = "{0:D2}" -f $n
        $dir = "C:\MT5_$num\MQL5\Experts\"
        if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
        
        try {
            Invoke-WebRequest -Uri $eaUrl -OutFile "$dir\$eaName" -ErrorAction Stop
            Write-Host "  [+] 已分发到 MT5_$num" -ForegroundColor Green
        } catch {
            Write-Host "  [-] 分发失败 MT5_$num : $_" -ForegroundColor Red
        }
    }

    # 步骤 2：等待 MT5 加载
    Write-Host "`n[*] 等待 MT5 加载 EA（${loadWaitSeconds}秒）..." -ForegroundColor Yellow
    Start-Sleep -Seconds $loadWaitSeconds

    # 步骤 3：用 Everything 搜索并删除所有 .ex5 文件
    Write-Host "`n[*] 正在搜索并删除已分发的 .ex5 文件..." -ForegroundColor Cyan
    
    # 使用 Everything 搜索所有 MT5 目录下的 .ex5 文件
    $searchResults = & $esPath -c "智汇矩阵" -o 100
    
    $deletedCount = 0
    foreach ($file in $searchResults) {
        if ($file -match "C:\\MT5_\d{2}\\MQL5\\Experts\\.*\.ex5$") {
            try {
                Remove-Item $file -Force -ErrorAction Stop
                Write-Host "  [x] 已删除: $file" -ForegroundColor Yellow
                $deletedCount++
            } catch {
                Write-Host "  [!] 删除失败: $file : $_" -ForegroundColor Red
            }
        }
    }

    Write-Host "`n[+] 本轮完成：分发 5 个实例，删除 $deletedCount 个文件" -ForegroundColor Green
    Write-Host "[*] 等待 60 秒后下一轮..." -ForegroundColor Gray
    Start-Sleep -Seconds 60
}
