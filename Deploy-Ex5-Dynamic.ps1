# ===== MT5 EA 动态分发脚本 =====
# 自动检测实例数量并分发 .ex5 文件

# [配置区]
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaUrl = "$githubBase/智汇矩阵V102版本(ssai).ex5"
$eaName = "智汇矩阵V102版本(ssai).ex5"

Write-Host "`n[=== MT5 EA 动态分发 ===]" -ForegroundColor Green

# 步骤 1：动态检测实例数量
Write-Host "`n[*] 正在检测 MT5 实例..." -ForegroundColor Cyan
$instances = Get-ChildItem "C:\" -Directory | Where-Object { $_.Name -match "^MT5_\d{2}$" } | Sort-Object Name

if ($instances.Count -eq 0) {
    Write-Host "[-] 未找到任何 MT5 实例！" -ForegroundColor Red
    exit 1
}

Write-Host "[+] 找到 $($instances.Count) 个实例：" -ForegroundColor Green
$instances | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }

# 步骤 2：分发 .ex5 到每个实例
Write-Host "`n[*] 开始分发 EA..." -ForegroundColor Cyan
$successCount = 0
$failCount = 0

foreach ($instance in $instances) {
    $dir = "$($instance.FullName)\MQL5\Experts\"
    if (!(Test-Path $dir)) { 
        New-Item $dir -Type Directory -Force | Out-Null 
    }
    
    try {
        Invoke-WebRequest -Uri $eaUrl -OutFile "$dir\$eaName" -ErrorAction Stop
        Write-Host "  [+] $($instance.Name) - 分发成功" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "  [-] $($instance.Name) - 分发失败 : $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n[+] 分发完成：成功 $successCount 个，失败 $failCount 个" -ForegroundColor Green
