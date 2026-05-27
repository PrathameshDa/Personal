# =========================================
# ENVIRONMENT SELECTION
# =========================================

Write-Host ""
Write-Host "====================================="
Write-Host "       GDB Maintenance Setup"
Write-Host "====================================="
Write-Host ""
Write-Host "Select Environment:"
Write-Host "1. PROD (Default)"
Write-Host "2. DEV"
Write-Host ""

$envChoice = Read-Host "Enter choice (1 or 2)"

if ($envChoice -eq "2") {

    $environment = "DEV"
    $extractPath = "C:\GDB_Maintenance\Dev"
    $taskName = "GDB Maintenance Dev"
    $taskTime = "11:30"
}
else {

    $environment = "PROD"
    $extractPath = "C:\GDB_Maintenance\Prod"
    $taskName = "GDB Maintenance Prod"
    $taskTime = "05:30"
}

Write-Host ""
Write-Host "Selected Environment : $environment"
Write-Host "Extract Path         : $extractPath"
Write-Host "Task Name            : $taskName"
Write-Host "Task Time            : $taskTime"
Write-Host ""

# =========================================
# CONFIGURATION
# =========================================

$zipUrl = "https://github.com/PrathameshDa/Personal/raw/refs/heads/main/gdb_modular.zip"

$downloadPath = "C:\Temp\project.zip"

$tempExtract = "C:\Temp\Extracted"

$currentUser = "$env:USERDOMAIN\$env:USERNAME"

# =========================================
# CREATE REQUIRED FOLDERS
# =========================================

New-Item -ItemType Directory -Force -Path "C:\Temp" | Out-Null
New-Item -ItemType Directory -Force -Path $extractPath | Out-Null

# =========================================
# CLEAN OLD CONTENT
# =========================================

Write-Host "Cleaning old extracted files..."

Get-ChildItem `
    -Path $extractPath `
    -Force `
    -ErrorAction SilentlyContinue | Remove-Item `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue

# =========================================
# DOWNLOAD ZIP
# =========================================

Write-Host ""
Write-Host "Downloading ZIP..."

$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest `
    -Uri $zipUrl `
    -OutFile $downloadPath `
    -Headers @{
        "User-Agent" = "Mozilla/5.0"
    }

# =========================================
# VALIDATE ZIP FILE
# =========================================

if (!(Test-Path $downloadPath)) {

    Write-Host "ZIP file download failed!"
    exit 1
}

$fileSize = (Get-Item $downloadPath).Length

if ($fileSize -lt 1000) {

    Write-Host "Downloaded file is invalid or too small."
    Write-Host "Check GitHub URL."
    exit 1
}

Write-Host "ZIP Download Successful"

# =========================================
# VALIDATE ZIP CONTENT
# =========================================

Add-Type -AssemblyName System.IO.Compression.FileSystem

try {

    [System.IO.Compression.ZipFile]::OpenRead($downloadPath).Dispose()

    Write-Host "ZIP validation successful"
}
catch {

    Write-Host "Invalid ZIP file"
    Write-Host $_.Exception.Message
    exit 1
}

# =========================================
# CLEAN TEMP EXTRACT FOLDER
# =========================================

if (Test-Path $tempExtract) {

    Remove-Item `
        $tempExtract `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

New-Item `
    -ItemType Directory `
    -Force `
    -Path $tempExtract | Out-Null

# =========================================
# EXTRACT ZIP
# =========================================

Write-Host ""
Write-Host "Extracting ZIP..."

try {

    Expand-Archive `
        -Path $downloadPath `
        -DestinationPath $tempExtract `
        -Force
}
catch {

    Write-Host "ZIP extraction failed."
    Write-Host $_.Exception.Message
    exit 1
}

# =========================================
# MOVE CONTENTS WITHOUT ROOT FOLDER
# =========================================

$rootFolder = Get-ChildItem `
    -Path $tempExtract `
    -Directory |
    Select-Object -First 1

if ($null -eq $rootFolder) {

    Write-Host "Unable to find extracted root folder."
    exit 1
}

Write-Host ""
Write-Host "Moving files to final destination..."

Get-ChildItem `
    -Path $rootFolder.FullName `
    -Force | ForEach-Object {

    Move-Item `
        -Path $_.FullName `
        -Destination $extractPath `
        -Force
}

# =========================================
# CLEAN TEMP FILES
# =========================================

Write-Host ""
Write-Host "Deleting temporary files..."

Remove-Item `
    $downloadPath `
    -Force `
    -ErrorAction SilentlyContinue

Remove-Item `
    $tempExtract `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue

# =========================================
# FIND GDBMaintenance.bat
# =========================================

$batFile = Get-ChildItem `
    -Path $extractPath `
    -Filter "GDBMaintenance.bat" `
    -Recurse |
    Select-Object -First 1

if ($null -eq $batFile) {

    Write-Host "GDBMaintenance.bat not found."
    exit 1
}

Write-Host ""
Write-Host "Found GDBMaintenance.bat:"
Write-Host $batFile.FullName

# =========================================
# ASK PASSWORD
# =========================================

Write-Host ""
$password = Read-Host "Enter password for $currentUser" -AsSecureString

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# =========================================
# DELETE EXISTING TASK
# =========================================

Write-Host ""
Write-Host "Removing old scheduled task if exists..."

schtasks /Delete `
    /TN "$taskName" `
    /F 2>$null

# =========================================
# CREATE TASK XML
# =========================================

Write-Host ""
Write-Host "Creating task configuration..."

$taskXmlPath = "C:\Temp\GDBMaintenanceTask.xml"

$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">

  <RegistrationInfo>
    <Author>$currentUser</Author>
    <Description>GDB Maintenance Scheduled Task</Description>
  </RegistrationInfo>

  <Triggers>

    <CalendarTrigger>

      <StartBoundary>2026-01-05T$($taskTime):00</StartBoundary>

      <Enabled>true</Enabled>

      <ScheduleByWeek>

        <WeeksInterval>2</WeeksInterval>

        <DaysOfWeek>
          <Monday />
        </DaysOfWeek>

      </ScheduleByWeek>

    </CalendarTrigger>

  </Triggers>

  <Principals>

    <Principal id="Author">

      <UserId>$currentUser</UserId>

      <LogonType>Password</LogonType>

      <RunLevel>HighestAvailable</RunLevel>

    </Principal>

  </Principals>

  <Settings>

    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>

    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>

    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>

    <AllowHardTerminate>true</AllowHardTerminate>

    <StartWhenAvailable>true</StartWhenAvailable>

    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>

    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>

    <AllowStartOnDemand>true</AllowStartOnDemand>

    <Enabled>true</Enabled>

    <Hidden>false</Hidden>

    <RunOnlyIfIdle>false</RunOnlyIfIdle>

    <WakeToRun>false</WakeToRun>

    <ExecutionTimeLimit>P3D</ExecutionTimeLimit>

    <Priority>7</Priority>

    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>

  </Settings>

  <Actions Context="Author">

    <Exec>

      <Command>$($batFile.FullName)</Command>

      <WorkingDirectory>$extractPath</WorkingDirectory>

    </Exec>

  </Actions>

</Task>
"@

$taskXml | Out-File `
    -FilePath $taskXmlPath `
    -Encoding Unicode

# =========================================
# CREATE SCHEDULED TASK
# =========================================

Write-Host ""
Write-Host "Creating Scheduled Task..."

schtasks /Create `
    /TN "$taskName" `
    /XML "$taskXmlPath" `
    /RU "$currentUser" `
    /RP "$plainPassword" `
    /F

# =========================================
# VALIDATE TASK CREATION
# =========================================

if ($LASTEXITCODE -eq 0) {

    Write-Host ""
    Write-Host "====================================="
    Write-Host "Scheduled Task Created Successfully"
    Write-Host "====================================="
    Write-Host "Environment : $environment"
    Write-Host "Task Name   : $taskName"
    Write-Host "Run User    : $currentUser"
    Write-Host "Schedule    : Every Alternate Monday"
    Write-Host "Run Time    : $taskTime"
    Write-Host "BAT File    : $($batFile.FullName)"
    Write-Host ""

    schtasks /Query `
        /TN "$taskName" `
        /V `
        /FO LIST
}
else {

    Write-Host ""
    Write-Host "Task creation failed."
}

# =========================================
# CLEAN TEMP XML
# =========================================

Remove-Item `
    $taskXmlPath `
    -Force `
    -ErrorAction SilentlyContinue
