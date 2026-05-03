# MT5 多账户运维 SOP

> 阿里云 Windows 服务器 | EA: 智汇矩阵 V102 版本 (ssai)  
> **能自动的不手动，能一条的不两条**

---

## 1. 全新部署（安装 MT5 + EA + Everything）

在服务器 PowerShell 中执行：

``powershell
# === MT5 自动化部署 V3.1 (新服务器纯净版) ===
$AccountCount = 5
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaName = "智汇矩阵 V102 版本 (ssai).ex5"

# 处理文件名中的空格
$eaUrl = "$githubBase/$([uri]::EscapeDataString($eaName))"

# --- 1. 部署 Everything 基础设施 ---
Write-Host "正在配置 Everything 环境..." -ForegroundColor Cyan
$installDir = "C:\Program Files\Everything"
if (!(Test-Path $installDir)) { New-Item $installDir -Type Directory -Force }

$everySetup = "$env:TEMP\EverythingSetup.exe"
$esExe = "$installDir\es.exe"

Invoke-WebRequest -Uri "$githubBase/Everything-1.4.1.1032.x86-Setup.exe" -OutFile $everySetup
Invoke-WebRequest -Uri "$githubBase/es.exe" -OutFile $esExe

Start-Process -FilePath $everySetup -ArgumentList "/S" -Wait

# --- 2. 安装并初始化 MT5 母本 ---
Write-Host "正在初始化 MT5 母本..." -ForegroundColor Cyan
$setupPath = "$env:TEMP\exness5setup.exe"
Invoke-WebRequest -Uri "$githubBase/exness5setup.exe" -OutFile $setupPath

Start-Process -FilePath $setupPath -ArgumentList "/path:C:\MT5_Master /auto" -Wait
Start-Sleep -Seconds 5
Stop-Process -Name "terminal64" -Force -ErrorAction SilentlyContinue

# --- 3. 核心分发逻辑 ---
1..$AccountCount | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"

    Write-Host "正在部署实例 $n..." -ForegroundColor Gray

    # 物理克隆
    if (!(Test-Path $target)) { Copy-Item "C:\MT5_Master" $target -Recurse -Force }

    # 下载并放置 EA
    $dir = "$target\MQL5\Experts"
    if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
    Invoke-WebRequest -Uri $eaUrl -OutFile "$dir/$eaName"

    # 生成桌面快捷方式
    $exePath = "$target\terminal64.exe"
    $Wsh = New-Object -ComObject WScript.Shell
    $lnk = "$([Environment]::GetFolderPath('Desktop'))\Account_$n.lnk"
    $sc = $Wsh.CreateShortcut($lnk)
    $sc.TargetPath = $exePath
    $sc.Arguments = "/portable /skipupdate"
    $sc.WorkingDirectory = $target
    $sc.Save()

    # 启动
    Start-Process -FilePath $exePath -ArgumentList "/portable /skipupdate" -WorkingDirectory $target
    Start-Sleep -Seconds 2
}

Write-Host "✅ 新服务器部署完成！Everything 及其命令行工具已就绪。" -ForegroundColor Yellow
``

---

## 2. 增量克隆（新增实例，自动续接序号）

``powershell
# ===== MT5 增量自动化部署 (自动续接序号版) =====

# [配置区]
$AddCount = 5  # 本次需要新增的数量
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaName = "智汇矩阵 V102 版本 (ssai).ex5"
$eaUrl = "$githubBase/$([uri]::EscapeDataString($eaName))"

# 1. 自动探测当前已存在的最大序号
Write-Host "正在扫描现有环境..." -ForegroundColor Cyan
$existingFolders = Get-ChildItem "C:\" -Filter "MT5_*" | Where-Object { $_.Name -match "MT5_\d{2}" }

if ($existingFolders) {
    $lastIndex = $existingFolders.Name | ForEach-Object { [int]($_.Split('_')[1]) } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    Write-Host "检测到当前最大序号为: $lastIndex" -ForegroundColor Yellow
} else {
    $lastIndex = 0
    Write-Host "未检测到现有环境，将从 01 开始创建。" -ForegroundColor Yellow
}

# 2. 执行增量克隆
$StartIndex = $lastIndex + 1
$EndIndex = $lastIndex + $AddCount

$StartIndex..$EndIndex | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"
    
    Write-Host "正在构建新环境: $target ..." -ForegroundColor Cyan
    
    # 克隆母本
    if (!(Test-Path $target)) { 
        Copy-Item "C:\MT5_Master" $target -Recurse -Force 
    }
    
    # 分发 EA
    $dir = "$target\MQL5\Experts"
    if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
    Invoke-WebRequest -Uri $eaUrl -OutFile "$dir/$eaName"
    
    # 创建桌面图标
    $exePath = "$target\terminal64.exe"
    $Wsh = New-Object -ComObject WScript.Shell
    $lnk = "$([Environment]::GetFolderPath('Desktop'))\Account_$n.lnk"
    $sc = $Wsh.CreateShortcut($lnk)
    $sc.TargetPath = $exePath
    $sc.Arguments = "/portable /skipupdate"
    $sc.WorkingDirectory = $target
    $sc.Save()

    # 拉起新实例
    Write-Host "正在拉起实例 $n..." -ForegroundColor Green
    Start-Process -FilePath $exePath -ArgumentList "/portable /skipupdate" -WorkingDirectory $target
    Start-Sleep -Seconds 3
}

Write-Host "✅ 增量部署完成！已从 $StartIndex 续接到 $EndIndex。" -ForegroundColor Yellow
``

---

## 3. EA 清除（秒级清理残留）

``powershell
# 1. 确保服务启动并留出索引时间
Write-Host "等待 Everything 索引初始化..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# 2. 定义 es.exe 路径
$esExe = "C:\Program Files\Everything\es.exe"

# 3. 执行秒级清理
$targets = & $esExe "智汇矩阵 V102 版本 (ssai).ex5"

if ($targets) {
    $targets | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item $_ -Force -ErrorAction SilentlyContinue
            Write-Host "已清理残留: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "未发现相关残留文件，环境纯净。" -ForegroundColor Green
}
``

---

## 4. EA 重新分发（补发到已有实例）

``powershell
# ===== 模块：EA 重新分发与实例启动 =====

# [配置区]
$AccountCount = 5 
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaName = "智汇矩阵 V102 版本 (ssai).ex5"
$eaUrl = "$githubBase/智汇矩阵 V102 版本 (ssai).ex5"

Write-Host "--- 开始执行 EA 补发流程 ---" -ForegroundColor Cyan

1..$AccountCount | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"
    $eaDir = "$target\MQL5\Experts\"

    # 1. 检查实例路径是否存在
    if (Test-Path $target) {
        # 2. 补发 EA 文件
        if (!(Test-Path $eaDir)) { New-Item $eaDir -Type Directory -Force }
        Write-Host "正在向 MT5_$n 推送 EA..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $eaUrl -OutFile "$eaDir/$eaName"

        # 3. 启动/拉起该实例
        Start-Process -FilePath "$target\terminal64.exe" -ArgumentList "/portable /skipupdate"
    } else {
        Write-Host "警告: 未找到路径 $target，跳过补发。" -ForegroundColor Red
    }
}

Write-Host "✅ 所有 EA 补发完成并已尝试拉起窗口。" -ForegroundColor Green
Write-Host "请在手动挂载 EA 后，再次运行 Everything 删除命令。" -ForegroundColor Yellow
``

---

## 手动配置（每个实例）

双击打开 Account → 登录 Exness → Ctrl+O → **Charts: 5000** → **Expert Advisors**: 勾选两项

- ✅ Allow algorithmic trading
- ✅ Allow DLL imports

---

## 仓库文件清单

| 文件 | 用途 |
|------|------|
| exness5setup.exe | MT5 Exness 安装器 |
| Everything-1.4.1.1032.x86-Setup.exe | Everything 静默安装包 |
| es.exe | Everything 命令行工具 |
| 智汇矩阵 V102 版本 (ssai).ex5 | EA 策略文件 |
| MT5-SOP.md | 本操作手册 |

---

*最后更新：2026-05-03 | 版本：4.0（脚本精简版）*