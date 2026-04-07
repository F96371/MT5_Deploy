# MT5 多账户隔离运维 SOP（终极精简版）

> 适用于阿里云 Windows 服务器 | 单账户 200 元业务标准流程  
> **核心原则：能自动的不手动，能一条的不两条**

---

## 🚀 一键部署脚本（推荐）

**在服务器上执行此脚本，自动完成所有可自动化步骤：**

```powershell
# ===== MT5 一键部署脚本 =====
# 复制到阿里云服务器 PowerShell 执行

# 1. 系统优化
Stop-Service wuauserv -Force; Set-Service wuauserv -StartupType Disabled
powercfg -setactive SCHEME_MIN; powercfg -change -monitor-timeout-ac 0; powercfg -change -standby-timeout-ac 0

# 2. 等待母本安装完成（手动安装到 C:\MT5_Master 后按回车）
Write-Host "请先安装 MT5 母本到 C:\MT5_Master，安装完成后按回车继续..." -ForegroundColor Yellow
Read-Host "按回车继续"

# 3. 克隆 5 个实例
1..5 | ForEach-Object { $n = "{0:D2}" -f $_; Copy-Item "C:\MT5_Master" "C:\MT5_$n" -Recurse -Force }

# 4. 生成桌面快捷方式 + 开机自启动
$Wsh = New-Object -ComObject WScript.Shell
1..5 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $Sc = $Wsh.CreateShortcut("$env:USERPROFILE\Desktop\Account_$n.lnk")
    $Sc.TargetPath = "C:\MT5_$n\terminal64.exe"; $Sc.Arguments = "/portable /skipupdate"
    $Sc.WorkingDirectory = "C:\MT5_$n"; $Sc.Save()
    Copy-Item "$env:USERPROFILE\Desktop\Account_$n.lnk" "$([Environment]::GetFolderPath('Startup'))\" -Force
}

# 5. 下载并分发 EA
$eaUrl = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main/Zhihui_Matrix_V102.ex5"
1..5 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $dir = "C:\MT5_$n\MQL5\Experts\"
    if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
    Invoke-WebRequest -Uri $eaUrl -OutFile "$dir\Zhihui_Matrix_V102.ex5" -Force
}

# 6. 创建日志清理脚本
$bat = @"
@echo off
for /d %%i in (C:\MT5_*) do (del /s /q "%%i\MQL5\Logs\*.log" 2>nul; del /s /q "%%i\MQL5\Files\*.log" 2>nul)
echo [%DATE% %TIME%] Logs Cleaned!
"@
$bat | Out-File "$env:USERPROFILE\Desktop\Clean_Logs.bat" -Encoding ASCII

Write-Host "✅ 部署完成！请手动登录 5 个 MT5 账户" -ForegroundColor Green
```

---

## 📝 唯一需要手动的步骤

### 步骤 1：下载并安装 MT5 母本
```powershell
# 下载 MT5 安装器
$mt5Url = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main/exness5setup.exe"
Invoke-WebRequest -Uri $mt5Url -OutFile "$env:USERPROFILE\Desktop\exness5setup.exe"

# 双击运行，安装路径选 C:\MT5_Master，装完关闭
Start-Process "$env:USERPROFILE\Desktop\exness5setup.exe"
```

### 步骤 2：运行上面的一键部署脚本

### 步骤 3：登录 5 个账户（每个约 1 分钟）
| 实例 | 操作 |
|------|------|
| Account_01 ~ Account_05 | 双击打开 → 登录 Exness → `Ctrl+O` → Charts: 5000 → Expert Advisors: 勾选两项 → 隐藏无关品种 |

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
$eaUrl = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main/Zhihui_Matrix_V102.ex5"
1..5 | ForEach-Object { $n = "{0:D2}" -f $_; $d = "C:\MT5_$n\MQL5\Experts\"; if (!(Test-Path $d)) { New-Item $d -Type Directory }; Invoke-WebRequest -Uri $eaUrl -OutFile "$d\Zhihui_Matrix_V102.ex5" -Force }

# 只创建快捷方式 + 自启动
$Wsh = New-Object -ComObject WScript.Shell; 1..5 | ForEach-Object { $n = "{0:D2}" -f $_; $Sc = $Wsh.CreateShortcut("$env:USERPROFILE\Desktop\Account_$n.lnk"); $Sc.TargetPath = "C:\MT5_$n\terminal64.exe"; $Sc.Arguments = "/portable /skipupdate"; $Sc.WorkingDirectory = "C:\MT5_$n"; $Sc.Save(); Copy-Item "$env:USERPROFILE\Desktop\Account_$n.lnk" "$([Environment]::GetFolderPath('Startup'))\" -Force }
```

### 清理所有实例（重装时用）
```powershell
Remove-Item "C:\MT5_*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\Desktop\Account_*.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$([Environment]::GetFolderPath('Startup'))\Account_*.lnk" -Force -ErrorAction SilentlyContinue
```

---

## 📦 文件清单（GitHub 仓库）

| 文件 | Raw 链接 | 用途 |
|------|---------|------|
| exness5setup.exe | `https://raw.githubusercontent.com/F96371/MT5_Deploy/main/exness5setup.exe` | MT5 安装器 |
| Zhihui_Matrix_V102.ex5 | `https://raw.githubusercontent.com/F96371/MT5_Deploy/main/Zhihui_Matrix_V102.ex5` | EA 策略文件 |
| MT5-SOP.md | `https://raw.githubusercontent.com/F96371/MT5_Deploy/main/MT5-SOP.md` | 本操作手册 |

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

---

*最后更新：2026-04-07 | 版本：2.0（全自动化）*
