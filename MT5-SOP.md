# MT5 多账户隔离运维 SOP（终极自动化版）

> 适用于阿里云 Windows 服务器 | 单账户 200 元业务标准流程  
> **核心原则：能自动的不手动，能一条的不两条**

---

## 🚀 一键部署脚本（推荐）

**在阿里云服务器 PowerShell 中直接执行以下脚本：**

```powershell
# ===== MT5 全流程自动化部署 (含母本安装) =====

# [配置区]
$githubBase = "https://ghproxy.net/https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaName = "Zhihui_Matrix_V102.ex5"

# 1. 下载并静默安装母本
Write-Host "正在下载并静默安装 MT5 母本..." -ForegroundColor Cyan
$setupPath = "$env:TEMP\exness5setup.exe"
Invoke-WebRequest -Uri "$githubBase/exness5setup.exe" -OutFile $setupPath
Start-Process -FilePath $setupPath -ArgumentList "/path:C:\MT5_Master /auto" -Wait
Stop-Process -Name "terminal64" -Force -ErrorAction SilentlyContinue

# 2. 批量克隆与环境隔离
Write-Host "正在克隆 5 个独立交易环境..." -ForegroundColor Cyan
1..5 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"
    if (!(Test-Path $target)) { Copy-Item "C:\MT5_Master" $target -Recurse -Force }
}

# 3. 从云端推送 EA 策略
Write-Host "正在从云端推送 EA 策略..." -ForegroundColor Cyan
1..5 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $dir = "C:\MT5_$n\MQL5\Experts\"
    if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
    Invoke-WebRequest -Uri "$githubBase/$eaName" -OutFile "$dir\$eaName"
}

# 4. 生成桌面快捷方式并注入开机自启
Write-Host "正在配置自启动快捷方式..." -ForegroundColor Cyan
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

Write-Host "✅ 所有流程已完成！请手动登录账户并设置 Max Bars=5000。" -ForegroundColor Green
```

---

## 📝 唯一需要手动的步骤

### 登录 5 个账户（每个约 1 分钟）

| 实例 | 操作 |
|------|------|
| Account_01 ~ Account_05 | 双击打开 → 登录 Exness → `Ctrl+O` → **Charts: 5000** → **Expert Advisors**: 勾选两项 → 隐藏无关品种 |

**必须勾选的两项：**
- ✅ Allow algorithmic trading
- ✅ Allow DLL imports

---

## 🔧 分项命令（按需使用）

### 检查部署状态
```powershell
# 实例数量
Get-ChildItem C:\ -Directory | Where-Object { $_.Name -match "MT5_\d\d" } | Measure-Object | Select-Object -ExpandProperty Count

# EA 文件检查
1..5 | ForEach-Object { $n = "{0:D2}" -f $_; Write-Host "MT5_$n : $((Test-Path "C:\MT5_$n\MQL5\Experts\*.ex5"))" }

# 自启动检查
Get-ChildItem "$([Environment]::GetFolderPath('Startup'))\Account_*.lnk" | Select-Object Name
```

### 单独执行某一步
```powershell
# 只克隆实例
1..5 | ForEach-Object { $n = "{0:D2}" -f $_; Copy-Item "C:\MT5_Master" "C:\MT5_$n" -Recurse -Force }

# 只分发 EA
$githubBase = "https://ghproxy.net/https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
1..5 | ForEach-Object { $n = "{0:D2}" -f $_; $d = "C:\MT5_$n\MQL5\Experts\"; if (!(Test-Path $d)) { New-Item $d -Type Directory }; Invoke-WebRequest -Uri "$githubBase/Zhihui_Matrix_V102.ex5" -OutFile "$d\Zhihui_Matrix_V102.ex5" }

# 只创建快捷方式 + 自启动
$Wsh = New-Object -ComObject WScript.Shell; 1..5 | ForEach-Object { $n = "{0:D2}" -f $_; $sc = $Wsh.CreateShortcut("$env:USERPROFILE\Desktop\Account_$n.lnk"); $sc.TargetPath = "C:\MT5_$n\terminal64.exe"; $sc.Arguments = "/portable /skipupdate"; $sc.WorkingDirectory = "C:\MT5_$n"; $sc.Save(); Copy-Item "$env:USERPROFILE\Desktop\Account_$n.lnk" "$([Environment]::GetFolderPath('Startup'))\" -Force }
```

### 清理所有实例（重装时用）
```powershell
Remove-Item "C:\MT5_*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\Desktop\Account_*.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$([Environment]::GetFolderPath('Startup'))\Account_*.lnk" -Force -ErrorAction SilentlyContinue
```

### 创建日志清理脚本
```powershell
$bat = @"
@echo off
for /d %%i in (C:\MT5_*) do (del /s /q "%%i\MQL5\Logs\*.log" 2>nul; del /s /q "%%i\MQL5\Files\*.log" 2>nul)
echo [%DATE% %TIME%] Logs Cleaned!
"@
$bat | Out-File "$env:USERPROFILE\Desktop\Clean_Logs.bat" -Encoding ASCII
```

---

## 📦 文件清单（GitHub 仓库）

| 文件 | Raw 链接 | 用途 |
|------|---------|------|
| exness5setup.exe | `https://ghproxy.net/https://raw.githubusercontent.com/F96371/MT5_Deploy/main/exness5setup.exe` | MT5 安装器 |
| Zhihui_Matrix_V102.ex5 | `https://ghproxy.net/https://raw.githubusercontent.com/F96371/MT5_Deploy/main/Zhihui_Matrix_V102.ex5` | EA 策略文件 |
| MT5-SOP.md | `https://ghproxy.net/https://raw.githubusercontent.com/F96371/MT5_Deploy/main/MT5-SOP.md` | 本操作手册 |

> 💡 **使用 ghproxy.net 加速** - 国内下载速度更快，无需代理

---

## ⚠️ 注意事项

| 项目 | 建议值 |
|------|--------|
| 内存 | 8GB 最多 15 实例，5 实例约占用 3-4GB |
| CPU | 2 核够用，4 核更稳 |
| 磁盘 | 预留 20GB+（日志会增长，每周清理） |
| 网络 | 确保 443/444 端口出栈正常（Exness 服务器） |
| 重启 | 阿里云后台重启后会自动拉起（自启动已配置） |

---

## 🆘 常见问题

**Q: 实例启动后闪退？**  
A: 检查是否以 `/portable` 模式启动，或母本安装路径是否正确。

**Q: EA 不运行？**  
A: `Ctrl+O` → Expert Advisors → 确认勾选 "Allow algorithmic trading" 和 "Allow DLL imports"。

**Q: 日志文件夹爆满？**  
A: 双击桌面 `Clean_Logs.bat` 手动清理，或设置每周一定时任务。

**Q: 下载速度慢？**  
A: 脚本已配置 ghproxy.net 加速，如遇墙可尝试切换代理。

---

## 📋 执行前检查清单

```powershell
# 确认 PowerShell 执行策略
Get-ExecutionPolicy
# 如果是 Restricted，执行：Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 确认磁盘空间
Get-PSDrive C | Select-Object Used, Free

# 确认网络连接
Test-Connection -ComputerName github.com -Count 2
```

---

*最后更新：2026-04-07 | 版本：3.0（全自动静默安装）*
