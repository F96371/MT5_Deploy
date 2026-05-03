# MT5 澶氳处鎴疯繍缁?SOP

> 闃块噷浜?Windows 鏈嶅姟鍣?| EA: 鏅烘眹鐭╅樀 V102 鐗堟湰 (ssai)  
> **鑳借嚜鍔ㄧ殑涓嶆墜鍔紝鑳戒竴鏉＄殑涓嶄袱鏉?*

---

## 1. 鍏ㄦ柊閮ㄧ讲锛堝畨瑁?MT5 + EA + Everything锛?
鍦ㄦ湇鍔″櫒 PowerShell 涓墽琛岋細

```powershell
# === MT5 鑷姩鍖栭儴缃?V3.1 (鏂版湇鍔″櫒绾噣鐗? ===
$AccountCount = 5
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaName = "鏅烘眹鐭╅樀 V102 鐗堟湰 (ssai).ex5"

# 澶勭悊鏂囦欢鍚嶄腑鐨勭┖鏍?$eaUrl = "$githubBase/$([uri]::EscapeDataString($eaName))"

# --- 1. 閮ㄧ讲 Everything 鍩虹璁炬柦 ---
Write-Host "姝ｅ湪閰嶇疆 Everything 鐜..." -ForegroundColor Cyan
$installDir = "C:\Program Files\Everything"
if (!(Test-Path $installDir)) { New-Item $installDir -Type Directory -Force }

$everySetup = "$env:TEMP\EverythingSetup.exe"
$esExe = "$installDir\es.exe"

Invoke-WebRequest -Uri "$githubBase/Everything-1.4.1.1032.x86-Setup.exe" -OutFile $everySetup
Invoke-WebRequest -Uri "$githubBase/es.exe" -OutFile $esExe

Start-Process -FilePath $everySetup -ArgumentList "/S" -Wait

# --- 2. 瀹夎骞跺垵濮嬪寲 MT5 姣嶆湰 ---
Write-Host "姝ｅ湪鍒濆鍖?MT5 姣嶆湰..." -ForegroundColor Cyan
$setupPath = "$env:TEMP\exness5setup.exe"
Invoke-WebRequest -Uri "$githubBase/exness5setup.exe" -OutFile $setupPath

Start-Process -FilePath $setupPath -ArgumentList "/path:C:\MT5_Master /auto" -Wait
Start-Sleep -Seconds 5
Stop-Process -Name "terminal64" -Force -ErrorAction SilentlyContinue

# --- 3. 鏍稿績鍒嗗彂閫昏緫 ---
1..$AccountCount | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"

    Write-Host "姝ｅ湪閮ㄧ讲瀹炰緥 $n..." -ForegroundColor Gray

    # 鐗╃悊鍏嬮殕
    if (!(Test-Path $target)) { Copy-Item "C:\MT5_Master" $target -Recurse -Force }

    # 涓嬭浇骞舵斁缃?EA
    $dir = "$target\MQL5\Experts"
    if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
    Invoke-WebRequest -Uri $eaUrl -OutFile "$dir\$eaName"

    # 鐢熸垚妗岄潰蹇嵎鏂瑰紡
    $exePath = "$target\terminal64.exe"
    $Wsh = New-Object -ComObject WScript.Shell
    $lnk = "$([Environment]::GetFolderPath('Desktop'))\Account_$n.lnk"
    $sc = $Wsh.CreateShortcut($lnk)
    $sc.TargetPath = $exePath
    $sc.Arguments = "/portable /skipupdate"
    $sc.WorkingDirectory = $target
    $sc.Save()

    # 鍚姩
    Start-Process -FilePath $exePath -ArgumentList "/portable /skipupdate" -WorkingDirectory $target
    Start-Sleep -Seconds 2
}

Write-Host "鉁?鏂版湇鍔″櫒閮ㄧ讲瀹屾垚锛丒verything 鍙婂叾鍛戒护琛屽伐鍏峰凡灏辩华銆? -ForegroundColor Yellow
```

---

## 2. 澧為噺鍏嬮殕锛堟柊澧炲疄渚嬶紝鑷姩缁帴搴忓彿锛?
```powershell
# ===== MT5 澧為噺鑷姩鍖栭儴缃?(鑷姩缁帴搴忓彿鐗? =====

# [閰嶇疆鍖篯
$AddCount = 5  # 鏈闇€瑕佹柊澧炵殑鏁伴噺
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaName = "鏅烘眹鐭╅樀 V102 鐗堟湰 (ssai).ex5"
$eaUrl = "$githubBase/$([uri]::EscapeDataString($eaName))"

# 1. 鑷姩鎺㈡祴褰撳墠宸插瓨鍦ㄧ殑鏈€澶у簭鍙?Write-Host "姝ｅ湪鎵弿鐜版湁鐜..." -ForegroundColor Cyan
$existingFolders = Get-ChildItem "C:\" -Filter "MT5_*" | Where-Object { $_.Name -match "MT5_\d{2}" }

if ($existingFolders) {
    $lastIndex = $existingFolders.Name | ForEach-Object { [int]($_.Split('_')[1]) } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    Write-Host "妫€娴嬪埌褰撳墠鏈€澶у簭鍙蜂负: $lastIndex" -ForegroundColor Yellow
} else {
    $lastIndex = 0
    Write-Host "鏈娴嬪埌鐜版湁鐜锛屽皢浠?01 寮€濮嬪垱寤恒€? -ForegroundColor Yellow
}

# 2. 鎵ц澧為噺鍏嬮殕
$StartIndex = $lastIndex + 1
$EndIndex = $lastIndex + $AddCount

$StartIndex..$EndIndex | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"
    
    Write-Host "姝ｅ湪鏋勫缓鏂扮幆澧? $target ..." -ForegroundColor Cyan
    
    # 鍏嬮殕姣嶆湰
    if (!(Test-Path $target)) { 
        Copy-Item "C:\MT5_Master" $target -Recurse -Force 
    }
    
    # 鍒嗗彂 EA
    $dir = "$target\MQL5\Experts"
    if (!(Test-Path $dir)) { New-Item $dir -Type Directory -Force }
    Invoke-WebRequest -Uri $eaUrl -OutFile "$dir\$eaName"
    
    # 鍒涘缓妗岄潰鍥炬爣
    $exePath = "$target\terminal64.exe"
    $Wsh = New-Object -ComObject WScript.Shell
    $lnk = "$([Environment]::GetFolderPath('Desktop'))\Account_$n.lnk"
    $sc = $Wsh.CreateShortcut($lnk)
    $sc.TargetPath = $exePath
    $sc.Arguments = "/portable /skipupdate"
    $sc.WorkingDirectory = $target
    $sc.Save()

    # 鎷夎捣鏂板疄渚?    Write-Host "姝ｅ湪鎷夎捣瀹炰緥 $n..." -ForegroundColor Green
    Start-Process -FilePath $exePath -ArgumentList "/portable /skipupdate" -WorkingDirectory $target
    Start-Sleep -Seconds 3
}

Write-Host "鉁?澧為噺閮ㄧ讲瀹屾垚锛佸凡浠?$StartIndex 缁帴鍒?$EndIndex銆? -ForegroundColor Yellow
```

---

## 3. EA 娓呴櫎锛堢绾ф竻鐞嗘畫鐣欙級

```powershell
# 1. 纭繚鏈嶅姟鍚姩骞剁暀鍑虹储寮曟椂闂?Write-Host "绛夊緟 Everything 绱㈠紩鍒濆鍖?.." -ForegroundColor Gray
Start-Sleep -Seconds 3

# 2. 瀹氫箟 es.exe 璺緞
$esExe = "C:\Program Files\Everything\es.exe"

# 3. 鎵ц绉掔骇娓呯悊
$targets = & $esExe "鏅烘眹鐭╅樀 V102 鐗堟湰 (ssai).ex5"

if ($targets) {
    $targets | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item $_ -Force -ErrorAction SilentlyContinue
            Write-Host "宸叉竻鐞嗘畫鐣? $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "鏈彂鐜扮浉鍏虫畫鐣欐枃浠讹紝鐜绾噣銆? -ForegroundColor Green
}
```

---

## 4. EA 閲嶆柊鍒嗗彂锛堣ˉ鍙戝埌宸叉湁瀹炰緥锛?
```powershell
# ===== 妯″潡锛欵A 閲嶆柊鍒嗗彂涓庡疄渚嬪惎鍔?=====

# [閰嶇疆鍖篯
$AccountCount = 5 
$githubBase = "https://raw.githubusercontent.com/F96371/MT5_Deploy/main"
$eaName = "鏅烘眹鐭╅樀 V102 鐗堟湰 (ssai).ex5"
$eaUrl = "$githubBase/鏅烘眹鐭╅樀 V102 鐗堟湰 (ssai).ex5"

Write-Host "--- 寮€濮嬫墽琛?EA 琛ュ彂娴佺▼ ---" -ForegroundColor Cyan

1..$AccountCount | ForEach-Object {
    $n = "{0:D2}" -f $_
    $target = "C:\MT5_$n"
    $eaDir = "$target\MQL5\Experts\"

    # 1. 妫€鏌ュ疄渚嬭矾寰勬槸鍚﹀瓨鍦?    if (Test-Path $target) {
        # 2. 琛ュ彂 EA 鏂囦欢
        if (!(Test-Path $eaDir)) { New-Item $eaDir -Type Directory -Force }
        Write-Host "姝ｅ湪鍚?MT5_$n 鎺ㄩ€?EA..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $eaUrl -OutFile "$eaDir\$eaName"

        # 3. 鍚姩/鎷夎捣璇ュ疄渚?        Start-Process -FilePath "$target\terminal64.exe" -ArgumentList "/portable /skipupdate"
    } else {
        Write-Host "璀﹀憡: 鏈壘鍒拌矾寰?$target锛岃烦杩囪ˉ鍙戙€? -ForegroundColor Red
    }
}

Write-Host "鉁?鎵€鏈?EA 琛ュ彂瀹屾垚骞跺凡灏濊瘯鎷夎捣绐楀彛銆? -ForegroundColor Green
Write-Host "璇峰湪鎵嬪姩鎸傝浇 EA 鍚庯紝鍐嶆杩愯 Everything 鍒犻櫎鍛戒护銆? -ForegroundColor Yellow
```

---

## 鎵嬪姩閰嶇疆锛堟瘡涓疄渚嬶級

鍙屽嚮鎵撳紑 Account 鈫?鐧诲綍 Exness 鈫?`Ctrl+O` 鈫?**Charts: 5000** 鈫?**Expert Advisors**: 鍕鹃€変袱椤?
- 鉁?Allow algorithmic trading
- 鉁?Allow DLL imports

---

## 浠撳簱鏂囦欢娓呭崟

| 鏂囦欢 | 鐢ㄩ€?|
|------|------|
| `exness5setup.exe` | MT5 Exness 瀹夎鍣?|
| `Everything-1.4.1.1032.x86-Setup.exe` | Everything 闈欓粯瀹夎鍖?|
| `es.exe` | Everything 鍛戒护琛屽伐鍏?|
| `鏅烘眹鐭╅樀 V102 鐗堟湰 (ssai).ex5` | EA 绛栫暐鏂囦欢 |
| `MT5-SOP.md` | 鏈搷浣滄墜鍐?|

---

*鏈€鍚庢洿鏂帮細2026-05-03 | 鐗堟湰锛?.0锛堣剼鏈簿绠€鐗堬級*
