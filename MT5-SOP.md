# MT5 多账户隔离运维 SOP（5 实例精简版）

> 适用于阿里云 Windows 服务器 | 单账户 200 元业务标准流程

---

## 第一阶段：系统基础环境审计


### 2. 电源优化
```powershell
powercfg -setactive SCHEME_MIN
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0
```

### 3. 创建目录
```powershell
New-Item -Path "C:\MT5_Master" -ItemType Directory -Force
```

---

## 第二阶段：母本安装与克隆

### 1. 安装母本（手动一次）
- 运行 `exness5setup.exe`
- **Settings** → 路径设为 `C:\MT5_Master`
- 安装完成后**立即关闭**

### 2. 批量克隆（5 个实例）
```powershell
1..5 | ForEach-Object { 
    $num = "{0:D2}" -f $_
    Copy-Item -Path "C:\MT5_Master" -Destination "C:\MT5_$num" -Recurse -Force 
}
```

---

## 第三阶段：快捷方式生成

```powershell
$WshShell = New-Object -ComObject WScript.Shell
1..5 | ForEach-Object {
    $num = "{0:D2}" -f $_
    $Shortcut = $WshShell.CreateShortcut("$([Environment]::GetFolderPath('Desktop'))\Account_$num.lnk")
    $Shortcut.TargetPath = "C:\MT5_$num\terminal64.exe"
    $Shortcut.Arguments = "/portable /skipupdate"
    $Shortcut.WorkingDirectory = "C:\MT5_$num"
    $Shortcut.Save()
}
```

---

## 第四阶段：EA 静默分发（一步到位）

```powershell
# 下载并分发到所有 5 个实例
$eaUrl = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main/智汇矩阵 V102 版本 (ssai).ex5"
1..5 | ForEach-Object {
    $num = "{0:D2}" -f $_
    $TargetDir = "C:\MT5_$num\MQL5\Experts\"
    if (!(Test-Path $TargetDir)) { New-Item $TargetDir -Type Directory -Force }
    Invoke-WebRequest -Uri $eaUrl -OutFile "$TargetDir\智汇矩阵 V102 版本 (ssai).ex5" -Force
}
```

---

## 第五阶段：开机自启动

```powershell
# 创建启动文件夹快捷方式
$StartupPath = [System.IO.Path]::Combine([Environment]::GetFolderPath('Startup'), "*.lnk")
1..5 | ForEach-Object {
    $num = "{0:D2}" -f $_
    Copy-Item "$([Environment]::GetFolderPath('Desktop'))\Account_$num.lnk" -Destination $([Environment]::GetFolderPath('Startup')) -Force
}
```

---

## 第六阶段：账户初始化（手动）

每个实例执行一次：

1. **登录** - 填写 Exness 账号密码和服务器
2. **减内存** - `Ctrl+O` → Charts → Max bars = `5000`
3. **开权限** - `Ctrl+O` → Expert Advisors → 勾选：
   - ✅ Allow algorithmic trading
   - ✅ Allow DLL imports
4. **清品种** - 市场报价窗口 → 右键 → Hide All

---

## 第七阶段：日志清理脚本

桌面新建 `Clean_Logs.bat`：
```batch
@echo off
for /d %%i in (C:\MT5_*) do (
    del /s /q "%%i\MQL5\Logs\*.log" 2>nul
    del /s /q "%%i\MQL5\Files\*.log" 2>nul
)
echo [%DATE% %TIME%] Logs Cleaned!
```

---

## 🖥️ 本地电脑远程操作阿里云

### 方式一：远程桌面 (RDP) 一键命令

在本地电脑创建 `Deploy-MT5.ps1`，填入服务器 IP 和密码后执行：

```powershell
# ===== 配置区 =====
$ServerIP = "你的阿里云 IP"
$Username = "Administrator"
$Password = "你的服务器密码"
# =================

# 创建远程会话
$SecurePwd = ConvertTo-SecureString $Password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential($Username, $SecurePwd)

# 远程执行克隆命令
Invoke-Command -ComputerName $ServerIP -Credential $Cred -ScriptBlock {
    1..5 | ForEach-Object { 
        $num = "{0:D2}" -f $_
        Copy-Item -Path "C:\MT5_Master" -Destination "C:\MT5_$num" -Recurse -Force 
    }
}
```

### 方式二：SSH（如果阿里云开了 OpenSSH）

```powershell
# 本地电脑执行
ssh Administrator@你的阿里云 IP

# 登录后执行 PowerShell 命令
powershell -Command "1..5 | ForEach-Object { Copy-Item -Path 'C:\MT5_Master' -Destination 'C:\MT5_$($_.ToString("00"))' -Recurse -Force }"
```

### 方式三：阿里云 Workbench（网页终端）

直接复制粘贴上面的 PowerShell 命令到网页控制台执行。

---

## 📋 快速检查清单

```powershell
# 检查实例数量
Get-ChildItem C:\ | Where-Object { $_.Name -match "MT5_\d\d" } | Measure-Object

# 检查 EA 是否到位
1..5 | ForEach-Object { 
    $num = "{0:D2}" -f $_
    Write-Host "MT5_$num : $((Get-ChildItem "C:\MT5_$num\MQL5\Experts\*.ex5" -ErrorAction SilentlyContinue).Count) 个 EA 文件"
}

# 检查自启动
Get-ChildItem "$([Environment]::GetFolderPath('Startup'))\*.lnk" | Select-Object Name
```

---

## ⚠️ 注意事项

| 项目 | 建议 |
|------|------|
| 内存 | 8GB 最多跑 15 个实例，5 个很轻松 |
| CPU | 2 核够用，4 核更稳 |
| 磁盘 | 预留 20GB+（日志会增长） |
| 网络 | 确保 443/444 端口出栈正常 |
| 重启 | 阿里云后台重启后会自动拉起 |

---

*最后更新：2026-04-07*
