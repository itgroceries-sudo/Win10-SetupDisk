<#
.SYNOPSIS
    Web Launcher for Win10-SetupDisk
    Downloads and runs Setup.cmd from GitHub
#>

# ตั้งค่า Security Protocol ให้รองรับ GitHub (TLS 1.2)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# URL ของไฟล์ Setup.cmd (Format เป็น Raw Link)
$Url = "https://raw.githubusercontent.com/itgroceries-sudo/Win10-SetupDisk/main/Setup.cmd"

# กำหนดตำแหน่งไฟล์ชั่วคราวในเครื่องผู้ใช้ (ใช้ %TEMP% เพื่อไม่ต้องขอสิทธิ์ Admin ในการเขียนไฟล์)
$DestPath = "$env:TEMP\ITG_Setup.cmd"

try {
    # แสดงสถานะ (English)
    Write-Host "Downloading Setup configuration..." -ForegroundColor Cyan

    # ดาวน์โหลดไฟล์จาก GitHub
    Invoke-WebRequest -Uri $Url -OutFile $DestPath -UseBasicParsing -ErrorAction Stop

    # ตรวจสอบขนาดไฟล์เพื่อความชัวร์ (เผื่อโหลดมาแล้วไฟล์ว่าง)
    if ((Get-Item $DestPath).Length -gt 0) {
        Write-Host "Launching Setup..." -ForegroundColor Green
        
        # สั่งรันไฟล์ .cmd และแยก Process ออกไป
        Start-Process -FilePath $DestPath -WorkingDirectory "$env:TEMP"
        
        # ปิดหน้าต่าง PowerShell ทันที
        Exit
    } else {
        throw "Downloaded file is empty."
    }
}
catch {
    # กรณีเกิดข้อผิดพลาด
    Write-Error "Error: Failed to launch setup. Details: $_"
    Read-Host "Press Enter to exit..."
}
