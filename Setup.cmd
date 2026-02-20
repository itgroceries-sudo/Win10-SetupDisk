<# : hybrid batch + powershell script
@powershell -noprofile -Window Hidden -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>

# ==============================================================================================
#  PROJECT: Win10+ Setup Disk (IT Groceries Shop Edition)
#  DESCRIPTION: Advanced Windows Setup & Windows To Go Creator
# ==============================================================================================
#  MODIFIED BY: IT Groceries Shop (TOE)
#  LAST UPDATE: 2026-01-05 (Added VMD Drivers Tab)
# ==============================================================================================

# --- [Configuration] ---
$Title = "Win10+ Setup Disk & Win2Go MOD BY: IT Groceries Shop"
$Host.UI.RawUI.BackgroundColor = "Gray"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

$host.ui.rawui.windowtitle = $title
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$Width = 500; $Height = 600

# Global variables
$Global:ImagePath = ""
$Global:dvd = $False
$Global:ISO = ""
$Global:USB = 0
$Global:SetUp = $True
$Global:ProcessRunning = $False
$Global:usbntfs = ""
$Global:usbfat32 = ""
$Global:Mounted = $False
$Global:BypassTPM = $False
$Global:CustomAutoUnattendPath = ""
$Global:AllowClose = $True

# File browser (AutoUnattend.xml)
$CustomAutoUnattendBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Title="Select AutoUnattend.xml file"
    Multiselect = $false
    Filter = 'XML Files (*.xml)|*.xml'
}

# File browser (ISO)
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Title="Select install.wim/esd in the ISO image or extracted source folder"
    Multiselect = $false
    Filter = 'ISO images (*.iso;*install.wim;*install.esd)|*.iso;*install.wim;*install.esd'
}

Function Copy_Progression ($Files,$Partition,$fs) {
    [long]$TotalBytes = ($Files | measure -Sum length).Sum
    [long]$Total1 = 0
    $index = 0
    $FilesCount = $Files.Count
    $StopWatch1 = [Diagnostics.Stopwatch]::StartNew()
    $Buffer = New-Object Byte[] (4MB)

    $MainProgressBar.Visible = $True
    $ProgressLabel.Visible = $True
    $ProgressLabel.Text = "File copying process is starting..."
    $MainProgressBar.Value = 0

    ForEach ($File in $Files) {
        $FileFullName = $File.fullname
        [long]$FileLength = $File.Length
        $index++
        $DestFile = $partition+$FileFullName.Substring($Global:iso.length)
        $DestDir= Split-Path $DestFile -Parent

        if (!(Test-Path $DestDir)){New-Item -ItemType Directory "$DestDir" -Force >$Null}
        $SourceFile = [io.file]::OpenRead($FileFullName)
        $DestinationFile = [io.file]::Create($DestFile)

        $OutputTextBox.AppendText("$index/$FilesCount - $(Split-Path $FileFullName -Leaf) is being copied...`r`n")
        $OutputTextBox.ScrollToCaret()

        $StopWatch2 = [Diagnostics.Stopwatch]::StartNew()
        [long]$Total2 = [long]$Count = 0

        do {
            $Count = $SourceFile.Read($buffer, 0, $buffer.Length)
            $DestinationFile.Write($buffer, 0, $Count)
            $Total2 += $Count
            $Total1 += $Count

            $CompletionRate1 = $Total1 / $TotalBytes * 100
            [int]$MSElapsed = [int]$StopWatch1.ElapsedMilliseconds
            if (($Total1 -ne $TotalBytes) -and ($Total1 -ne 0)) {
                [int]$RemainingSeconds1 = $MSElapsed * ($TotalBytes / $Total1  - 1) / 1000
            } else {[int]$RemainingSeconds1 = 0}

            $MainProgressBar.Value = [math]::Min(100, [math]::Max(0, [int]$CompletionRate1))
            $ProgressLabel.Text = "Completed: {0:F1}% - {1} minutes {2} seconds remaining" -f $CompletionRate1,[math]::Truncate($RemainingSeconds1/60),($RemainingSeconds1%60)

            $Form.Refresh()
            [System.Windows.Forms.Application]::DoEvents()

        } while ($Count -gt 0)

        $StopWatch2.Stop()
        $StopWatch2.Reset()
        $SourceFile.Close()
        $DestinationFile.Close()

        $OutputTextBox.AppendText("$(Split-Path $FileFullName -Leaf) completed.`r`n")
        $OutputTextBox.ScrollToCaret()
    }

    $MainProgressBar.Value = 100
    $ProgressLabel.Text = "File copying process completed!"
    $OutputTextBox.AppendText("All files copied successfully.`r`n")
    $OutputTextBox.ScrollToCaret()

    $StopWatch1.Stop()
    $StopWatch1.Reset()
    $Buffer=$Null
}

Function Show_Error ($message) {
    $OutputTextBox.AppendText("ERROR: $message`r`n")
    $OutputTextBox.ScrollToCaret()
    $MainProgressBar.Visible = $False
    $ProgressLabel.Visible = $False
    $ProgressLabel.Text = "An error occurred!"
    $ProcessRunning = $False
    Enable_Controls
}

# ---------------------------------------------------------
# FUNCTION: DOWNLOAD ISO (AUTO - FIDO)
# ---------------------------------------------------------
Function Launch_Fido_Downloader {
    $FidoPath = "$env:TEMP\Fido.ps1"
    $FidoUrl = "https://raw.githubusercontent.com/pbatard/Fido/master/Fido.ps1"

    try {
        $OutputTextBox.AppendText("Fetching Fido (Auto Downloader)...`r`n")
        $OutputTextBox.ScrollToCaret()
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $FidoUrl -OutFile $FidoPath -UseBasicParsing
    } catch {
        Show_Error "Failed to download Fido. Please try 'Download (Browser)' option."
        return
    }

    if (Test-Path $FidoPath) {
        $OutputTextBox.AppendText("Launching Fido...`r`n")
        $OutputTextBox.ScrollToCaret()
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$FidoPath`"" -Wait
        $OutputTextBox.AppendText("Process finished. Please select the downloaded ISO.`r`n")
        $OutputTextBox.ScrollToCaret()
        [System.Windows.Forms.MessageBox]::Show("If download is complete, please select 'Select .ISO File' to continue.", "Download Completed")
    }
}

# ---------------------------------------------------------
# FUNCTION: DOWNLOAD VMD DRIVERS (PROJECT VMD)
# ---------------------------------------------------------
Function Launch_VMD_Project {
    # [ITG] URL Updated to .ps1
    $VMDUrl = "https://raw.githubusercontent.com/itgroceries-sudo/VMD-USB-Builder/main/USB_Builder.ps1" 
    $VMDPath = "$env:TEMP\USB_Builder.ps1"

    try {
        $OutputTextBox.AppendText("Fetching VMD Drivers Project...`r`n")
        $OutputTextBox.ScrollToCaret()
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $VMDUrl -OutFile $VMDPath -UseBasicParsing
        
        if (Test-Path $VMDPath) {
            $OutputTextBox.AppendText("Launching VMD Installer...`r`n")
            $OutputTextBox.ScrollToCaret()
            # [FIX] Execute .ps1 using PowerShell engine
            Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$VMDPath`"" -Wait
            $OutputTextBox.AppendText("VMD Installer finished.`r`n")
        }
    } catch {
        Show_Error "Failed to fetch VMD Project. Check your internet or GitHub URL."
    }
    $OutputTextBox.ScrollToCaret()
}

# ---------------------------------------------------------
# FUNCTION: DOWNLOAD ISO (MANUAL - BROWSER SPOOF)
# ---------------------------------------------------------
Function Open_Browser_Spoof ($TargetUrl) {
    $UA = "Mozilla/5.0 (iPad; CPU OS 13_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/91.0.4472.77 Mobile/15E148 Safari/604.1"
    
    $RandID = Get-Random
    $TempProfile = "$env:TEMP\ITG_Browser_Spoof_$RandID"
    New-Item -ItemType Directory -Path $TempProfile -Force | Out-Null

    $EdgePath = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"
    $ChromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    
    if (Test-Path $EdgePath) {
        Start-Process -FilePath $EdgePath -ArgumentList "--user-agent=""$UA"" --user-data-dir=""$TempProfile"" --no-first-run --no-default-browser-check ""$TargetUrl"""
    } elseif (Test-Path $ChromePath) {
        Start-Process -FilePath $ChromePath -ArgumentList "--user-agent=""$UA"" --user-data-dir=""$TempProfile"" --no-first-run --no-default-browser-check ""$TargetUrl"""
    } else {
        Start-Process $TargetUrl
    }
}

Function Launch_Browser_Downloader {
    $FormDL = New-Object System.Windows.Forms.Form
    $FormDL.Text = "Download (Browser)"; $FormDL.Size = New-Object System.Drawing.Size(300, 160)
    $FormDL.StartPosition = "CenterParent"; $FormDL.BackColor = "Gray"; $FormDL.ForeColor = "White"
    $FormDL.FormBorderStyle = 'FixedToolWindow'; $FormDL.TopMost = $True

    $LabelDL = New-Object System.Windows.Forms.Label
    $LabelDL.Location = New-Object System.Drawing.Point(10, 10); $LabelDL.Size = New-Object System.Drawing.Size(260, 20)
    $LabelDL.Text = "Select Version to Open in Browser:"

    $BtnWin10 = New-Object System.Windows.Forms.Button
    $BtnWin10.Location = New-Object System.Drawing.Point(20, 40); $BtnWin10.Size = New-Object System.Drawing.Size(240, 30)
    $BtnWin10.Text = "Windows 10 (Direct ISO)"
    $BtnWin10.BackColor = "White"; $BtnWin10.ForeColor = "Black"
    $BtnWin10.Add_Click({ 
        Open_Browser_Spoof "https://www.microsoft.com/software-download/windows10ISO" 
        $FormDL.DialogResult = "OK"; $FormDL.Close()
    })

    $BtnWin11 = New-Object System.Windows.Forms.Button
    $BtnWin11.Location = New-Object System.Drawing.Point(20, 80); $BtnWin11.Size = New-Object System.Drawing.Size(240, 30)
    $BtnWin11.Text = "Windows 11 (Direct ISO)"
    $BtnWin11.BackColor = "White"; $BtnWin11.ForeColor = "Black"
    $BtnWin11.Add_Click({ 
        Open_Browser_Spoof "https://www.microsoft.com/software-download/windows11" 
        $FormDL.DialogResult = "OK"; $FormDL.Close()
    })

    $FormDL.Controls.AddRange(@($LabelDL, $BtnWin10, $BtnWin11))
    $FormDL.ShowDialog($Form)
    
    $OutputTextBox.AppendText("Browser opened in Tablet Mode.`r`n")
    $OutputTextBox.AppendText("Please download ISO and then 'Select .ISO File'.`r`n")
    $OutputTextBox.ScrollToCaret()
}

Function Update_bcd ($partition){
    bcdedit /store $partition\boot\bcd /set '{default}' bootmenupolicy Legacy >$Null
    bcdedit /store $partition\EFI\Microsoft\boot\bcd /set '{default}' bootmenupolicy Legacy >$Null
    remove-item "$partition\boot\bcd.*" -force -ErrorAction SilentlyContinue
    remove-item "$partition\EFI\Microsoft\boot\bcd.*" -force -ErrorAction SilentlyContinue
}

Function Disable_Controls {
    $TabControl.Enabled = $False
    $ISOSourceList.Enabled = $False
    $USBDiskList.Enabled = $False
    $Windows.Enabled = $False
    $Wintogo.Enabled = $False
    $OKButton.Enabled = $False
    $ExitButton.Text = "Exit"
    $BypassTPMCheckbox.Enabled = $False
    $SelectAutoUnattendButton.Enabled = $False
    $Global:ProcessRunning = $True
    $WTGSelectButton.Enabled = $False
}

Function Enable_Controls {
    $TabControl.Enabled = $True
    $ISOSourceList.Enabled = $True
    $USBDiskList.Enabled = $True
    if ($WTGListBox.Visible -eq $True) { 
        $Windows.Enabled = $False
        $Wintogo.Enabled = $True
        $BypassTPMCheckbox.Enabled = $False
        $USBDiskList.Enabled = $False
    } else {
        $Windows.Enabled = $True
        $Wintogo.Enabled = $True
        if ($Windows.Checked) {
            $BypassTPMCheckbox.Enabled = $True
            if (!$BypassTPMCheckbox.Checked) {
                $SelectAutoUnattendButton.Enabled = $True
                $ClearAutoUnattendButton.Enabled = $True
            } else {
                $SelectAutoUnattendButton.Enabled = $False
                $ClearAutoUnattendButton.Enabled = $True
            }
        } else {
            $BypassTPMCheckbox.Enabled = $False
            $SelectAutoUnattendButton.Enabled = $False
            $ClearAutoUnattendButton.Enabled = $True
        }
    }
    $Global:ProcessRunning = $False
    if (!$Wintogo.Checked) {
        $WTGSelectButton.Enabled = $False
    } else {
        if ($WTGListBox.Visible -eq $True) {
            $WTGSelectButton.Enabled = $True
        } else {
            $WTGSelectButton.Enabled = $False
        }
    }
}

Function Start_Process {
    if ($ProcessRunning) { return }

    # Get confirmation
    $result = [System.Windows.Forms.MessageBox]::Show(
        "The USB device will be converted to MBR schema, repartitioned and formatted.`n`nAll partitions and data currently on the USB device will be deleted.`n`nAre you sure you want to continue?",
        "WARNING",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::No) { return }

    Disable_Controls

    $OutputTextBox.Clear()
    $OutputTextBox.AppendText("Process is starting...`r`n")
    $OutputTextBox.ScrollToCaret()

    try {
        # ISO mounting
        if($Global:dvd){
            $OutputTextBox.AppendText("Mounting and checking ISO image...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            # Check if ISO is already mounted, get drive letter
            If($Global:ISO = (Get-DiskImage $Global:ImagePath|Get-Volume).DriveLetter){
                $Global:Mounted = $True
            }Else{
                # Mount ISO and get drive letter
                $Global:Mounted = $False
                If(!($Global:ISO = (Mount-DiskImage $Global:ImagePath|Get-Volume).DriveLetter)){
                    Show_Error "Failed to mount ISO file"
                    return
                }
            }
            $Global:ISO = $Global:ISO + ":"
        }Else{
            $Global:ISO = $Global:ImagePath
        }

        # Stop system service
        Stop-Service ShellHWDetection -ErrorAction SilentlyContinue >$Null
        $ProgressPreference="SilentlyContinue"
        $OutputTextBox.AppendText("Preparation operations completed.`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # Clear USB disk
        $OutputTextBox.AppendText("Cleaning USB disk and converting to MBR partition scheme...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        "Select disk $Global:USB`nclean`nconvert MBR`nexit"|diskpart >$Null
        If($LASTEXITCODE -ne 0){
            Show_Error "Diskpart operations failed (Code: $LASTEXITCODE)"
            return
        }

        $OutputTextBox.AppendText("USB disk successfully cleaned and converted to MBR.`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # Create FAT32 partition
        $OutputTextBox.AppendText("Creating FAT32 boot partition and marking as active...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        Try{
            If($Global:SetUp){
                $Global:usbfat32 = (New-Partition -DiskNumber $Global:usb -Size 1GB -AssignDriveLetter -IsActive|
                    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "BOOT").DriveLetter + ":"
            } else {
                $Global:usbfat32 = (New-Partition -DiskNumber $Global:usb -Size 100MB -AssignDriveLetter -IsActive|
                    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM").DriveLetter + ":"
            }
        }
        Catch{
            Show_Error "Failed to create FAT32 partition"
            return
        }

        $PartitionSize = (Get-Volume ($Global:usbfat32 -Replace ".$")).Size/1GB
        If($PartitionSize -eq 0){
            Show_Error "FAT32 partition size is 0 GB"
            return
        }

        $OutputTextBox.AppendText("FAT32 partition successfully created ($($PartitionSize.ToString("F2")) GB).`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # File size check
        If($Global:SetUp){
            $Files32 = Get-ChildItem $Global:iso\boot, $Global:iso\efi, $Global:iso\sources\boot.wim, $Global:iso\bootmgr.*, $Global:iso\bootmgr -Recurse -File -Force
            $FilesSize = ($Files32 | measure -Sum Length).Sum/1GB
            $OutputTextBox.AppendText("FAT32 file size check: $($FilesSize.ToString("F2")) GB required.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            If ($FilesSize -gt $PartitionSize){
                Show_Error "FAT32 partition is too small ($($PartitionSize.ToString("F2")) GB available, $($FilesSize.ToString("F2")) GB required)"
                return
            }

            $OutputTextBox.AppendText("FAT32 partition size is sufficient.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()
        }

        # Create NTFS partition
        $OutputTextBox.AppendText("Creating NTFS setup partition...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        Try{
            If($Global:SetUp){$Label="Win Setup"} Else {$Label="Windows To Go"}
            $Global:usbntfs = (New-Partition -DiskNumber $Global:usb -UseMaximumSize -AssignDriveLetter|
                Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label).DriveLetter + ":"
        }
        Catch{
            Show_Error "Failed to create NTFS partition"
            return
        }

        $PartitionSize = (Get-Volume ($Global:usbntfs -Replace ".$")).Size/1GB
        If($PartitionSize -eq 0){
            Show_Error "NTFS partition size is 0 GB"
            return
        }

        $OutputTextBox.AppendText("NTFS partition successfully created ($($PartitionSize.ToString("F2")) GB).`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # NTFS file size check
        If($Global:SetUp){
            $FilesNTFS = Get-ChildItem $Global:iso -Recurse -File -Force
            $FilesSize = ($FilesNTFS | measure -Sum Length).Sum/1GB
            $OutputTextBox.AppendText("NTFS file size check: $($FilesSize.ToString("F2")) GB required.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            If($FilesSize -gt $PartitionSize){
                Show_Error "NTFS partition is too small ($($PartitionSize.ToString("F2")) GB available, $($FilesSize.ToString("F2")) GB required)"
                return
            }

            $OutputTextBox.AppendText("NTFS partition size is sufficient.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()
        }

        Start-Service ShellHWDetection -erroraction silentlycontinue >$Null

        # File copying or image application
        If($Global:SetUp){
            $OutputTextBox.AppendText("Starting file copying process...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            Copy_Progression $Files32 $Global:usbfat32 "FAT32"
            Copy_Progression $Filesntfs $Global:usbntfs "NTFS"

        } Else {
            # Windows To Go - Version selection in main GUI
            $OutputTextBox.AppendText("Reading version information for Windows To Go...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            # ISO path debug
            $OutputTextBox.AppendText("ISO path: $Global:ISO`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            # Check if install.wim file exists
            $installWimPath = "$Global:ISO\Sources\Install.wim"
            $OutputTextBox.AppendText("Install.wim path: $installWimPath`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            if (!(Test-Path $installWimPath)) {
                Show_Error "Install.wim file not found: $installWimPath"
                return
            }

            try {
                $WindowsImages = Get-WindowsImage -ImagePath $installWimPath
                if ($WindowsImages.Count -gt 0) {
                    # Create list for version selection
                    $WTGListBox.Items.Clear()
                    foreach ($Image in $WindowsImages) {
                        $WTGListBox.Items.Add("$(($Image.ImageName).Trim()) (Index: $($Image.ImageIndex))")
                    }
                    $WTGListBox.SelectedIndex = 0
                    $WTGListBox.Visible = $True
                    $WTGSelectButton.Visible = $True
                    $OutputTextBox.AppendText("Select one of the listed Windows versions and click the 'Select' button.`r`n")
                    $OutputTextBox.ScrollToCaret()
                    return
                } else {
                    Show_Error "No Windows image found in the selected ISO file"
                    return
                }
            } catch {
                Show_Error "Error reading Windows image information: $($_.Exception.Message)"
                return
            }
        }

        # Update BCD
        $OutputTextBox.AppendText("Updating BCD...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()
        Update_BCD $Global:usbfat32

        # Hide drive letter
        $OutputTextBox.AppendText("Removing drive letter to hide FAT32 boot partition...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()
        Get-Volume ($Global:usbfat32 -replace ".$")|Get-Partition| Remove-PartitionAccessPath -accesspath $Global:usbfat32

        # Eject ISO
        If($Global:DVD){
            $OutputTextBox.AppendText("Ejecting mounted ISO image...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()
            If(!$Global:Mounted){DisMount-DiskImage $Global:ImagePath >$Null}
        }

        # Write additional files
        if ($Global:SetUp) {
            Write_Additional_Files $Global:usbntfs $Global:CustomAutoUnattendPath $Global:BypassTPM
        }

        # Completed
        $MainProgressBar.Value = 100
        $ProgressLabel.Text = "All operations completed successfully!"
        $OutputTextBox.AppendText("`r`n=== OPERATIONS COMPLETED ===`r`n")
        $OutputTextBox.AppendText("Disk successfully created!`r`n")
        $OutputTextBox.AppendText("You can safely eject the USB disk.`r`n")
        $OutputTextBox.ScrollToCaret()

    } catch {
        Show_Error "Unexpected error: $($_.Exception.Message)"
    } finally {
        Enable_Controls
    }
}

Function Apply_WTG_Image {
    Disable_Controls

    if (-not $WTGListBox.SelectedItem) {
        $OutputTextBox.AppendText("Please select a Windows version.`r`n")
        return
    }

    $WTGListBox.Visible = $False
    $WTGSelectButton.Visible = $False
    $WTGSelectButton.Enabled = $False

    $SelectedItem = $WTGListBox.SelectedItem
    [int]$SelectedIndex = $SelectedItem.ToString().Split('(')[1].Split(':')[1].TrimEnd(')')

    $OutputTextBox.AppendText("Applying Windows To Go image (Index: $SelectedIndex)...`r`n")
    $OutputTextBox.ScrollToCaret()
    $MainProgressBar.Visible = $True
    $ProgressLabel.Visible = $True
    $ProgressLabel.Text = "Applying Windows To Go image. This process may take a long time, please wait..."
    $MainProgressBar.Style = "Marquee"
    $MainProgressBar.MarqueeAnimationSpeed = 20
    $Form.Refresh()

    try {
        $installWimPath = "$Global:ISO\Sources\Install.wim"
        $jobScript = {param($installWimPath,$usbntfs,$index);Expand-WindowsImage -ImagePath $installWimPath -ApplyPath "$($usbntfs)\" -Index $index}
        $job=Start-Job $jobScript -ArgumentList $installWimPath, $Global:usbntfs, $SelectedIndex

        do {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        } until ($job.State -ne "Running")

        $MainProgressBar.Style = "Continuous"
        $MainProgressBar.Value = 100
        $ProgressLabel.Text = "Windows To Go image applied!"

        If($job.State -ne "Completed"){
            $jobError = Receive-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force
            Show_Error "An error occurred while applying the image: $jobError"
            return
        }

        Remove-Job -Job $job -Force
        $OutputTextBox.AppendText("Windows To Go image successfully applied.`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # BCD settings
        $OutputTextBox.AppendText("Preparing BCD boot configuration...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        bcdboot $Global:usbntfs\windows /s $Global:usbfat32 /f ALL
        If(!(Test-Path $Global:usbfat32\bootmgr)){Copy-Item $Global:ISO\bootmgr $Global:usbfat32\bootmgr}
        If(!(Test-Path $Global:usbfat32\bootmgr.efi)){Copy-Item $Global:ISO\bootmgr $Global:usbfat32\bootmgr.efi}

        # Continue
        Continue_Process

    } catch {
        Show_Error "An error occurred while applying the Windows To Go image: $($_.Exception.Message)"
    }
}

Function Continue_Process {
    # Update BCD
    $OutputTextBox.AppendText("Updating BCD...`r`n")
    $OutputTextBox.ScrollToCaret()
    $Form.Refresh()
    Update_BCD $Global:usbfat32

    # Hide drive letter
    $OutputTextBox.AppendText("Removing drive letter to hide FAT32 boot partition...`r`n")
    $OutputTextBox.ScrollToCaret()
    $Form.Refresh()
    Get-Volume ($Global:usbfat32 -replace ".$")|Get-Partition| Remove-PartitionAccessPath -accesspath $Global:usbfat32

    # Eject ISO
    If($Global:DVD){
        $OutputTextBox.AppendText("Ejecting mounted ISO image...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()
        If(!$Global:Mounted){DisMount-DiskImage $Global:ImagePath >$Null}
    }

    # Completed
    $MainProgressBar.Value = 100
    $ProgressLabel.Text = "All operations completed successfully!"
    $OutputTextBox.AppendText("`r`n=== OPERATIONS COMPLETED ===`r`n")
    $OutputTextBox.AppendText("Disk successfully created!`r`n")
    $OutputTextBox.AppendText("You can safely eject the USB disk.`r`n")
    $OutputTextBox.ScrollToCaret()

    Enable_Controls
}

Function Write_Additional_Files($usbntfs, $customPath, $bypassTPM) {
    $OutputTextBox.AppendText("Writing additional files...`r`n")
    $OutputTextBox.ScrollToCaret()

    $targetAutoUnattend = Join-Path $usbntfs "AutoUnattend.xml"
    $targetauto = Join-Path $usbntfs "auto.cmd"

    # URL Sources
    $urlXml = "https://raw.githubusercontent.com/AveYo/MediaCreationTool.bat/main/bypass11/AutoUnattend.xml"
    $urlCmd = "https://raw.githubusercontent.com/AveYo/MediaCreationTool.bat/main/bypass11/auto.cmd"

    $hasInstallImage = Get-Item "$usbntfs\sources\install.*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'install\.(wim|esd)$' }

    if ($hasInstallImage) {
        # กรณีเลือกไฟล์ XML เอง
        if ($customPath -ne "" -and (Test-Path $customPath)) {
            try {
                Copy-Item $customPath $targetAutoUnattend -Force
                $OutputTextBox.AppendText("Custom AutoUnattend.xml file copied.`r`n")
            } catch {
                $OutputTextBox.AppendText("Error copying custom file: $($_.Exception.Message)`r`n")
            }
        } 
        # กรณีติ๊ก Bypass Win11 (โหลดจาก URL)
        elseif ($bypassTPM) {
            try {
                $OutputTextBox.AppendText("Downloading Bypass XML from GitHub...`r`n")
                Invoke-WebRequest -Uri $urlXml -OutFile $targetAutoUnattend -UseBasicParsing
                $OutputTextBox.AppendText("AutoUnattend.xml downloaded successfully.`r`n")
                
                $OutputTextBox.AppendText("Downloading Auto.cmd from GitHub...`r`n")
                Invoke-WebRequest -Uri $urlCmd -OutFile $targetauto -UseBasicParsing
                $OutputTextBox.AppendText("Auto.cmd downloaded successfully.`r`n")
            } catch {
                $OutputTextBox.AppendText("FAILED to download bypass files. Please check internet connection.`r`n")
            }
        }
    }
    $OutputTextBox.ScrollToCaret()
}

# Administrator control
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    If($param -eq "UAC_ERROR"){
        [System.Windows.Forms.MessageBox]::Show("UAC elevation for Administrator privileges failed!`n`nRight-click on the script and select 'Run as administrator'.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }

    If($ScriptPath.Length -gt 0){
        Start-Process "$ScriptPath" "UAC_ERROR" -Verb runAs; exit
    }

    If($PSCommandPath.Length -gt 0){
        Start-Process PowerShell -Verb runAs -ArgumentList "-f ""$PSCommandPath"" ""UAC_ERROR"""; exit
    }

    $ScriptPath = [Environment]::GetCommandLineArgs()[0]
    Start-Process "$ScriptPath" "UAC_ERROR" -Verb runAs; exit
}

# Main Form
$Form = New-Object System.Windows.Forms.Form -Property @{
    TopMost = $False; ShowIcon = $True; ControlBox = $True
    ForeColor = "White"; BackColor = "Gray"; Font = 'Consolas,10'
    Text = "$Title"; Width = $Width; Height = $Height
    StartPosition = "CenterScreen"; SizeGripStyle = "Hide"
    ShowInTaskbar = $True; MaximizeBox = $False; 
    MinimizeBox = $True 
    FormBorderStyle = 'FixedSingle'
}

# USB disk control
$FromDiskDrive = Get-CimInstance Win32_DiskDrive | Where-Object {
    $_.InterfaceType -eq 'USB' -or
    $_.MediaType -match 'External' -or
    $_.Model -match 'VHD|Virtual|Sanal' -or
    $_.Caption -match 'VHD|Virtual|Sanal' -or
    $_.PNPDeviceID -match 'VHD|MSFT'
}

# Tab control
$TabControl = New-Object System.Windows.Forms.TabControl -Property @{
    Location = New-Object System.Drawing.Point(10, 10)
    Size = New-Object System.Drawing.Size(460, 330)
}

# Main tab
$MainTab = New-Object System.Windows.Forms.TabPage -Property @{
    Text = "Setup Disk"
    BackColor = "Gray"
    ForeColor = "White"
}

# VMD Drivers Tab (NEW)
$VMDTab = New-Object System.Windows.Forms.TabPage -Property @{
    Text = "VMD Drivers"
    BackColor = "Gray"
    ForeColor = "White"
}

# VMD Tab Controls
$VMDLabel = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(20, 20)
    Size = New-Object System.Drawing.Size(400, 40)
    Text = "Download and Install Intel VMD Drivers automatically from IT Groceries GitHub Repository."
    ForeColor = "White"
    BackColor = "Gray"
}

$VMDDownloadBtn = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(130, 80)
    Size = New-Object System.Drawing.Size(200, 40)
    Text = "Launch VMD Installer"
    BackColor = "White"
    ForeColor = "Black"
}

$VMDDownloadBtn.Add_Click({
    Launch_VMD_Project
})

$VMDTab.Controls.Add($VMDLabel)
$VMDTab.Controls.Add($VMDDownloadBtn)

# How to use tab
$HowToTab = New-Object System.Windows.Forms.TabPage -Property @{
    Text = "How to Use?"
    BackColor = "Gray"
    ForeColor = "White"
}

$HowToText = New-Object System.Windows.Forms.RichTextBox -Property @{
    Location = New-Object System.Drawing.Point(10, 10)
    Size = New-Object System.Drawing.Size(430, 290)
    BackColor = "Gray"
    ForeColor = "White"
    ReadOnly = $True
    BorderStyle = "None"
    Font = "Arial,9"
    Text = @"
1- Connect your USB device.

2- Click the Windows ISO button and select the ISO file or the install.wim/esd file in the extracted folder.
ATTENTION: The esd file causes an error in the Windows To Go process.

3- Select "Target USB Disk" from the dropdown menu.

4- Select the "Windows Setup Disk" or "Windows To Go" option.

5- If you selected "Windows Setup Disk", you can optionally check the "Bypass Windows 11 system requirements" option.

6- Optionally, you can select your own automatic installation file using the "Select Custom AutoUnattend.xml File" button.

7- Click "Create Disk" to create a Windows Setup Disk or Windows To Go environment.
"@
}
$HowToTab.Controls.Add($HowToText)

$TNCTRLinkLabel = New-Object System.Windows.Forms.LinkLabel -Property @{
    Location = New-Object System.Drawing.Point(230, 540) 
    Size = New-Object System.Drawing.Size(460, 20)
    Text = "Blog"
    TextAlign = "MiddleCenter"
    LinkColor = [System.Drawing.Color]::White 
}

$TNCTRLinkLabel.Links.Add(0, $TNCTRLinkLabel.Text.Length, "https://itgroceries.blogspot.com/")

$TNCTRLinkLabel.Add_LinkClicked({
    param($sender, [System.Windows.Forms.LinkLabelLinkClickedEventArgs]$e)
    [System.Diagnostics.Process]::Start($e.Link.LinkData)
})

$GithubLinkLabel = New-Object System.Windows.Forms.LinkLabel -Property @{
    Location = New-Object System.Drawing.Point(-200, 540) 
    Size = New-Object System.Drawing.Size(460, 20)
    Text = "Github"
    TextAlign = "MiddleCenter"
    LinkColor = [System.Drawing.Color]::White 
}

$GithubLinkLabel.Links.Add(0, $GithubLinkLabel.Text.Length, "https://github.com/itgroceries-sudo/Win10-SetupDisk")

$GithubLinkLabel.Add_LinkClicked({
    param($sender, [System.Windows.Forms.LinkLabelLinkClickedEventArgs]$e)
    [System.Diagnostics.Process]::Start($e.Link.LinkData)
})

# Output text box
$OutputTextBox = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(10, 350)
    Size = New-Object System.Drawing.Size(460, 130)
    Multiline = $True
    ScrollBars = "Vertical"
    ReadOnly = $True
    BackColor = "Black"
    ForeColor = "White"
    Font = "Consolas,9"
    BorderStyle = "FixedSingle"
}

# Progress bar
$MainProgressBar = New-Object System.Windows.Forms.ProgressBar -Property @{
    Location = New-Object System.Drawing.Point(10, 490)
    Size = New-Object System.Drawing.Size(460, 25)
    Minimum = 0
    Maximum = 100
    Value = 0
    Style = "Continuous"
    Visible = $False
}

# Progress label
$ProgressLabel = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(10, 520)
    Size = New-Object System.Drawing.Size(460, 20)
    Text = ""
    ForeColor = "White"
    BackColor = "Gray"
    Font = "Arial,9"
    TextAlign = "MiddleCenter"
    Visible = $False
}

# ISO file path
$Label1 = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(20, 15)
    Size = New-Object System.Drawing.Size(400, 20)
    Text = "Windows (ISO or extracted source folder)"
    ForeColor = "White"
    BackColor = "Gray"
}

$ISOFile = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(20,35)
    Size = New-Object System.Drawing.Size(410,24)
    BackColor = "White"; ForeColor = "Black"
    ReadOnly = $True
    BorderStyle = "FixedSingle"
}

# Target USB disk
$TargetUSB = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(20,80)
    Text = "Target USB Disk"
    Size = New-Object System.Drawing.Size(200,20)
    ForeColor = "White"
    BackColor = "Gray"
}

$USBDiskList = New-Object System.Windows.Forms.ComboBox -Property @{
    DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    Location = New-Object System.Drawing.Point(20,100)
    Size = New-Object System.Drawing.Size(410,22)
}

# Radio buttons
$Windows = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(50,155)
    Text = "Windows Setup Disk"
    Size = New-Object System.Drawing.Size(190,20)
    Checked = $True
    ForeColor = "White"
    BackColor = "Gray"
}

$Wintogo = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(280,155)
    Text = "Windows To Go"
    Size = New-Object System.Drawing.Size(140,20)
    Checked = $False
    ForeColor = "White"
    BackColor = "Gray"
}

# Checkbox
$BypassTPMCheckbox = New-Object System.Windows.Forms.CheckBox -Property @{
    Location = New-Object System.Drawing.Point(65, 180)
    Text = "Bypass Windows 11 system requirements"
    Size = New-Object System.Drawing.Size(330, 20)
    ForeColor = "White"
    BackColor = "Gray"
    Enabled = $True
}

# AutoUnattend Select button
$SelectAutoUnattendButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(45,210)
    Text = "Select Custom Unattend.xml File"
    Size = New-Object System.Drawing.Size(275,30)
    Enabled = $True
}

# Clear button
$ClearAutoUnattendButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(325, 210)
    Text = "Clear"
    Size = New-Object System.Drawing.Size(80, 30)
    Enabled = $True 
}

$ToolTip = New-Object System.Windows.Forms.ToolTip
$ToolTip.Active = $True
$ToolTip.ShowAlways = $True
$ToolTip.SetToolTip($ClearAutoUnattendButton, "Refreshes USB Disk List and clears user selections. `nIt is recommended to use this button before starting a new process.")


# WTG List (hidden)
$WTGListBox = New-Object System.Windows.Forms.ListBox -Property @{
    Location = New-Object System.Drawing.Point(10, 200)
    Size = New-Object System.Drawing.Size(360, 100)
    Visible = $False
}

# [ITG] Dropdown for ISO Source
$ISOSourceList = New-Object System.Windows.Forms.ComboBox
$ISOSourceList.Location = New-Object System.Drawing.Point(45, 250)
$ISOSourceList.Size = New-Object System.Drawing.Size(150, 26)
$ISOSourceList.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$ISOSourceList.BackColor = [System.Drawing.Color]::White
$ISOSourceList.ForeColor = [System.Drawing.Color]::Black
$ISOSourceList.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard 
$ISOSourceList.Items.Add("[ Select Source ]") # Index 0 (Placeholder)
$ISOSourceList.Items.Add("Select .ISO File")        # Index 1
$ISOSourceList.Items.Add("Download (Auto)")         # Index 2
$ISOSourceList.Items.Add("Download (Browser)")      # Index 3
$ISOSourceList.SelectedIndex = 0 

$OKButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(205, 250)
    Size = New-Object System.Drawing.Size(110, 26)
    Text = "Create Disk"
    Enabled = $False
}

$ExitButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(325, 250)
    Size = New-Object System.Drawing.Size(80, 26)
    Text = "Exit"
}

$WTGSelectButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(360, 210)
    Size = New-Object System.Drawing.Size(100, 70)
    Text = "Select"
    Visible = $False
}

# Populate USB disk list
$USBDisks=@()
Foreach ($Disk in $Disks){
    $FriendlyName = ($Disk.Caption).PadRight(40).substring(0,35)
    $USBDisks+=$Disk.Index
    $USBDiskList.Items.Add(("{0,-30}{1,10:n2} GB" -f $FriendlyName,($Disk.Size/1GB))) >$Null
}
$USBDiskList.SelectedIndex = 0

# Event handlers
$ISOSourceList.Add_SelectedIndexChanged({
    if ($ISOSourceList.SelectedIndex -eq 1) { # Select .ISO
        If ($FileBrowser.ShowDialog() -ne "Cancel"){
            $Global:ImagePath = $FileBrowser.filename
            If($Global:ImagePath.Split(".")[-1] -eq "iso"){
                $Global:dvd = $True
                $ISOFile.Text = Split-Path -Path $Global:ImagePath -leaf
            }Else{
                $Global:dvd = $False
                $Global:ImagePath=Split-Path $Global:ImagePath -Parent|Split-Path -Parent
                $ISOFile.Text = $Global:ImagePath
            }
            if(($ISOFile.Text).length -gt 44){
                $ISOFile.Text = $Global:ImagePath.PadRight(100).substring(0,43)+"..."
            }
            $OKButton.Enabled = $True
            $OKButton.Focus()
        }
    }
    elseif ($ISOSourceList.SelectedIndex -eq 2) { # Download Auto
        Launch_Fido_Downloader
    }
    elseif ($ISOSourceList.SelectedIndex -eq 3) { # Download Browser
        Launch_Browser_Downloader
    }
    
    # Reset to Placeholder (Index 0) to avoid re-triggering logic
    Start-Sleep -Milliseconds 200
    $ISOSourceList.SelectedIndex = 0
})

$OKButton.Add_Click({
    $Global:USB = $USBDisks[$USBDiskList.SelectedIndex]
    $Global:SetUp = $Windows.Checked
    $Global:BypassTPM = $BypassTPMCheckbox.Checked                                    
    Start_Process
})

$ExitButton.Add_Click({
    $Global:AllowClose = $True  
    $Form.Close()
})

$WTGSelectButton.Add_Click({
    Apply_WTG_Image
})

$Form.Add_FormClosing({
    if ($Global:DVD -and $Global:Mounted) {
        try {
            Dismount-DiskImage -ImagePath $Global:ImagePath -ErrorAction SilentlyContinue
        } catch {
        }
    }

    if ($_.CloseReason -eq 'UserClosing' -and -not $Global:AllowClose) {
        $_.Cancel = $True
    }
})

# --- Auto Refresh USB Timer (Every 1 Second) ---
$RefreshTimer = New-Object System.Windows.Forms.Timer
$RefreshTimer.Interval = 1000 
$RefreshTimer.Add_Tick({
    $CurrentSelectedDriveIndex = -1
    if ($USBDiskList.SelectedIndex -ge 0 -and $Script:USBDisks.Count -gt $USBDiskList.SelectedIndex) {
        $CurrentSelectedDriveIndex = $Script:USBDisks[$USBDiskList.SelectedIndex]
    }

    $NewDisks = Get-CimInstance Win32_DiskDrive | Where-Object {
        $_.InterfaceType -eq 'USB' -or
        $_.MediaType -match 'External' -or
        $_.Model -match 'VHD|Virtual|Sanal' -or
        $_.Caption -match 'VHD|Virtual|Sanal' -or
        $_.PNPDeviceID -match 'VHD|MSFT'
    }

    $USBDiskList.Items.Clear()
    $Script:Disks = $NewDisks
    $Script:USBDisks = @()

    Foreach ($Disk in $Script:Disks){
        $FriendlyName = ($Disk.Caption).PadRight(40).substring(0,35)
        $Script:USBDisks += $Disk.Index
        $USBDiskList.Items.Add(("{0,-30}{1,10:n2} GB" -f $FriendlyName,($Disk.Size/1GB))) >$Null
    }

    $RestoredIndex = -1
    for ($i = 0; $i -lt $Script:USBDisks.Count; $i++) {
        if ($Script:USBDisks[$i] -eq $CurrentSelectedDriveIndex) {
            $RestoredIndex = $i
            break
        }
    }

    if ($RestoredIndex -ne -1) {
        $USBDiskList.SelectedIndex = $RestoredIndex
    } elseif ($USBDiskList.Items.Count -gt 0) {
        $USBDiskList.SelectedIndex = 0
    }
})
$RefreshTimer.Start()

# Clear button event handler
$ClearAutoUnattendButton.Add_Click({
    if (-not $Windows.Checked) {
        $Windows.Checked = $True
    }
    if ($BypassTPMCheckbox.Checked) {
        $BypassTPMCheckbox.Checked = $False
    }
    $Global:CustomAutoUnattendPath = ""
    $ISOFile.Text = ""
    $OKButton.Enabled = $False
    $BypassTPMCheckbox.Enabled = $True
    $ClearAutoUnattendButton.Enabled = $True
    $ProgressLabel.Text = ""
    $MainProgressBar.Visible = $False
    $OutputTextBox.Clear()
    
    $USBDiskList.Items.Clear()
    $FromDiskDrive = Get-CimInstance Win32_DiskDrive | Where-Object {
        $_.InterfaceType -eq 'USB' -or
        $_.MediaType -match 'External' -or
        $_.Model -match 'VHD|Virtual|Sanal' -or
        $_.Caption -match 'VHD|Virtual|Sanal' -or
        $_.PNPDeviceID -match 'VHD|MSFT'
    }
    $Disks = $FromDiskDrive
    $USBDisks=@()
    Foreach ($Disk in $Disks){
        $FriendlyName = ($Disk.Caption).PadRight(40).substring(0,35)
        $USBDisks+=$Disk.Index
        $USBDiskList.Items.Add(("{0,-30}{1,10:n2} GB" -f $FriendlyName,($Disk.Size/1GB))) >$Null
    }
    if ($USBDiskList.Items.Count -gt 0) {
        $USBDiskList.SelectedIndex = 0
    } else {
        $USBDiskList.SelectedIndex = -1
    }

    if ($SelectAutoUnattendButton.Enabled -eq $False) {
        $SelectAutoUnattendButton.Enabled = $True
    }
    $Global:CustomAutoUnattendPath = ""
    $SelectAutoUnattendButton.Text = "Select custom Unattend.xml file"
    $ClearAutoUnattendButton.Enabled = $True 
})

# AutoUnattend selection
$SelectAutoUnattendButton.Add_Click({
    if ($CustomAutoUnattendBrowser.ShowDialog() -ne "Cancel") {
        $Global:CustomAutoUnattendPath = $CustomAutoUnattendBrowser.FileName
        $SelectAutoUnattendButton.Text = "$($Global:CustomAutoUnattendPath.Split('\')[-1]) selected"
        $ClearAutoUnattendButton.Enabled = $True
        $BypassTPMCheckbox.Enabled = $False
    }
})

$Windows.Add_CheckedChanged({
    if ($Windows.Checked) {
        $BypassTPMCheckbox.Enabled = $True
        if (!$BypassTPMCheckbox.Checked) {
            $SelectAutoUnattendButton.Enabled = $True
            $ClearAutoUnattendButton.Enabled = $True
        } else {
            $SelectAutoUnattendButton.Enabled = $False
            $ClearAutoUnattendButton.Enabled = $True
        }
    } else {
        $BypassTPMCheckbox.Enabled = $False
        $SelectAutoUnattendButton.Enabled = $False
        $ClearAutoUnattendButton.Enabled = $True
    }
})

$BypassTPMCheckbox.Add_CheckedChanged({
    if ($Windows.Checked) {
        if ($BypassTPMCheckbox.Checked) {
            $SelectAutoUnattendButton.Enabled = $False
            $ClearAutoUnattendButton.Enabled = $True
            $Global:CustomAutoUnattendPath = ""
            $SelectAutoUnattendButton.Text = "Select custom Unattend.xml file"
        } else {
            $SelectAutoUnattendButton.Enabled = $True
            $ClearAutoUnattendButton.Enabled = $True
        }
    }
})

$Wintogo.Add_CheckedChanged({
    if ($Wintogo.Checked) {
        $BypassTPMCheckbox.Enabled = $False
        $SelectAutoUnattendButton.Enabled = $False
        $ClearAutoUnattendButton.Enabled = $True
        $Global:CustomAutoUnattendPath = ""
        $SelectAutoUnattendButton.Text = "Select custom Unattend.xml file"
    }
})

$TabControl.Controls.Add($MainTab)
$TabControl.Controls.Add($VMDTab)
$TabControl.Controls.Add($HowToTab)
$MainTab.Controls.Add($WTGListBox)
$MainTab.Controls.Add($WTGSelectButton)
$MainTab.Controls.Add($Label1)
$MainTab.Controls.Add($ISOFile)
$MainTab.Controls.Add($TargetUSB)
$MainTab.Controls.Add($USBDiskList)
$MainTab.Controls.Add($Windows)
$MainTab.Controls.Add($Wintogo)
$MainTab.Controls.Add($OKButton)
$MainTab.Controls.Add($ExitButton)
$MainTab.Controls.Add($BypassTPMCheckbox)
$MainTab.Controls.Add($SelectAutoUnattendButton)
$MainTab.Controls.Add($ClearAutoUnattendButton)

# [FIX] ADD Dropdown Last & BringToFront to avoid Z-Order issues
$MainTab.Controls.Add($ISOSourceList)
$ISOSourceList.BringToFront()

$Form.Controls.Add($GithubLinkLabel)
$Form.Controls.Add($TNCTRLinkLabel)
$Form.Controls.Add($TabControl)
$Form.Controls.Add($OutputTextBox)
$Form.Controls.Add($MainProgressBar)
$Form.Controls.Add($ProgressLabel)

$OutputTextBox.AppendText("`r`nReady`r`nSelect ISO file and click the 'Create Disk' button.`r`n")
$OutputTextBox.ScrollToCaret()

$Form.Controls.Add($ProgressLabel)

# ==========================================
# [IT GROCERIES SHOP] DYNAMIC ICON LOADING
# ==========================================
$IconUrl = "https://itgroceries.blogspot.com/favicon.ico"
$IconPath = "$env:TEMP\itg_favicon.ico"

try {
    # ดาวน์โหลดไอคอนมาเก็บไว้ที่ Temp ก่อน
    Invoke-WebRequest -Uri $IconUrl -OutFile $IconPath -UseBasicParsing -ErrorAction SilentlyContinue
    if (Test-Path $IconPath) {
        $Form.Icon = New-Object System.Drawing.Icon($IconPath)
    }
} catch {
    # หากโหลดไม่ได้ ให้ข้ามไป (ใช้ไอคอน Default ของ Windows)
}
# ==========================================

$Form.ShowDialog()

$Form.ShowDialog()
