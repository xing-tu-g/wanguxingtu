param(
	[string]$ApkPath = "builds/wanguxingtu-m70-b01-004535-debug.apk",
	[string]$PackageName = "com.wanguxingtu.mvp",
	[string]$Serial = "",
	[string]$ScreenshotPath = (Join-Path $env:TEMP "wanguxingtu-smoke.png"),
	[string]$AdbBin = "adb",
	[int]$LaunchWaitSeconds = 5,
	[string]$WaitForLogPattern = "万古星图首页 ready",
	[int]$WaitTimeoutSeconds = 45,
	[int]$MinScreenshotBytes = 50000,
	[int]$LogcatLines = 2600
)

$ErrorActionPreference = "Stop"
$script:ActiveSerial = $Serial

function Invoke-Native {
	param(
		[string]$FilePath,
		[string[]]$Arguments
	)
	$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
	$startInfo.FileName = $FilePath
	$startInfo.Arguments = Join-NativeArguments $Arguments
	$startInfo.RedirectStandardOutput = $true
	$startInfo.RedirectStandardError = $true
	$startInfo.UseShellExecute = $false
	$process = [System.Diagnostics.Process]::new()
	$process.StartInfo = $startInfo
	[void]$process.Start()
	$stdout = $process.StandardOutput.ReadToEnd()
	$stderr = $process.StandardError.ReadToEnd()
	$process.WaitForExit()
	$lines = @()
	if (-not [string]::IsNullOrWhiteSpace($stdout)) {
		$lines += $stdout -split "`r?`n" | Where-Object { $_ -ne "" }
	}
	if (-not [string]::IsNullOrWhiteSpace($stderr)) {
		$lines += $stderr -split "`r?`n" | Where-Object { $_ -ne "" }
	}
	return @{
		Status = $process.ExitCode
		Output = $lines
	}
}

function Invoke-NativeBytes {
	param(
		[string]$FilePath,
		[string[]]$Arguments
	)
	$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
	$startInfo.FileName = $FilePath
	$startInfo.Arguments = Join-NativeArguments $Arguments
	$startInfo.RedirectStandardOutput = $true
	$startInfo.RedirectStandardError = $true
	$startInfo.UseShellExecute = $false
	$process = [System.Diagnostics.Process]::new()
	$process.StartInfo = $startInfo
	[void]$process.Start()
	$memory = [System.IO.MemoryStream]::new()
	$process.StandardOutput.BaseStream.CopyTo($memory)
	$stderr = $process.StandardError.ReadToEnd()
	$process.WaitForExit()
	$lines = @()
	if (-not [string]::IsNullOrWhiteSpace($stderr)) {
		$lines += $stderr -split "`r?`n" | Where-Object { $_ -ne "" }
	}
	return @{
		Status = $process.ExitCode
		Bytes = $memory.ToArray()
		Output = $lines
	}
}

function Join-NativeArguments {
	param([string[]]$Arguments)
	$escaped = @()
	foreach ($argument in $Arguments) {
		if ($argument -match '[\s"]') {
			$escaped += '"' + ($argument -replace '"', '\"') + '"'
		} else {
			$escaped += $argument
		}
	}
	return ($escaped -join " ")
}

function Invoke-Adb {
	param([string[]]$Arguments)
	$adbArgs = @()
	if (-not [string]::IsNullOrWhiteSpace($script:ActiveSerial)) {
		$adbArgs += @("-s", $script:ActiveSerial)
	}
	$adbArgs += $Arguments
	return Invoke-Native $AdbBin $adbArgs
}

function Wait-ForAdbLog {
	param(
		[string]$Pattern,
		[int]$TimeoutSeconds
	)
	if ([string]::IsNullOrWhiteSpace($Pattern)) {
		return $true
	}
	$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
	while ((Get-Date) -lt $deadline) {
		$logcat = Invoke-Adb @("logcat", "-d", "-t", "$LogcatLines")
		$logText = $logcat.Output -join "`n"
		if ($logText -match [regex]::Escape($Pattern)) {
			Write-Step "ADB_WAIT_LOG_MATCH=$Pattern"
			return $true
		}
		Start-Sleep -Seconds 1
	}
	Write-Step "ADB_WAIT_LOG_TIMEOUT=$Pattern"
	return $false
}

function Write-Step {
	param([string]$Message)
	Write-Output $Message
}

if (-not (Test-Path -LiteralPath $ApkPath -PathType Leaf)) {
	Write-Step "APK_MISSING=$ApkPath"
	exit 2
}

$resolvedScreenshotPath = [System.IO.Path]::GetFullPath($ScreenshotPath)
$screenshotDir = [System.IO.Path]::GetDirectoryName($resolvedScreenshotPath)
if (-not [string]::IsNullOrEmpty($screenshotDir) -and -not (Test-Path -LiteralPath $screenshotDir -PathType Container)) {
	New-Item -ItemType Directory -Path $screenshotDir | Out-Null
}

Write-Step "APK_PATH=$ApkPath"
Write-Step "PACKAGE_NAME=$PackageName"
Write-Step "SCREENSHOT_PATH=$resolvedScreenshotPath"

$devicesResult = Invoke-Native $AdbBin @("devices")
$devices = $devicesResult.Output
Write-Step "ADB_DEVICES_BEGIN"
$devices | ForEach-Object { Write-Output $_ }
Write-Step "ADB_DEVICES_END"
if ($devicesResult.Status -ne 0) {
	Write-Step "ADB_DEVICES_FAILED"
	exit $devicesResult.Status
}

$readyDeviceLines = @($devices | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "^List of devices" })
if (-not [string]::IsNullOrWhiteSpace($Serial)) {
	$serialLine = @($devices | Where-Object { $_ -match "^$([regex]::Escape($Serial))\s+" }) | Select-Object -First 1
	if ($serialLine.Count -eq 0) {
		Write-Step "ADB_DEVICE_NOT_FOUND=$Serial"
		exit 10
	}
	if ($serialLine -notmatch "\bdevice\b") {
		Write-Step "ADB_DEVICE_NOT_READY=$serialLine"
		exit 10
	}
} elseif ($readyDeviceLines.Count -eq 0) {
	Write-Step "ADB_DEVICE_NOT_READY=no_online_device"
	exit 10
} elseif ($readyDeviceLines.Count -eq 1) {
	$script:ActiveSerial = (($readyDeviceLines[0] -split "\s+")[0]).Trim()
	Write-Step "ADB_AUTO_SERIAL=$script:ActiveSerial"
} else {
	Write-Step "ADB_MULTIPLE_ONLINE_DEVICES=$($readyDeviceLines -join '; ')"
	exit 10
}

$install = Invoke-Adb @("install", "-r", $ApkPath)
$install.Output | ForEach-Object { Write-Output $_ }
if ($install.Status -ne 0 -or -not (($install.Output -join "`n") -match "Success")) {
	Write-Step "ADB_INSTALL_FAILED=$($install.Status)"
	exit 3
}
Write-Step "ADB_INSTALL_SUCCESS"

$forceStop = Invoke-Adb @("shell", "am", "force-stop", $PackageName)
if ($forceStop.Status -ne 0) {
	$forceStop.Output | ForEach-Object { Write-Output $_ }
	Write-Step "ADB_FORCE_STOP_FAILED=$($forceStop.Status)"
	exit 4
}

$logcatClear = Invoke-Adb @("logcat", "-c")
if ($logcatClear.Status -ne 0) {
	Write-Step "ADB_LOGCAT_CLEAR_FAILED=$($logcatClear.Status)"
	exit 4
}

$launch = Invoke-Adb @("shell", "monkey", "-p", $PackageName, "-c", "android.intent.category.LAUNCHER", "1")
$launch.Output | ForEach-Object { Write-Output $_ }
if ($launch.Status -ne 0 -or -not (($launch.Output -join "`n") -match "Events injected: 1")) {
	Write-Step "ADB_LAUNCH_FAILED=$($launch.Status)"
	exit 5
}
Write-Step "ADB_LAUNCH_SUCCESS"

Start-Sleep -Seconds $LaunchWaitSeconds
if (-not (Wait-ForAdbLog $WaitForLogPattern $WaitTimeoutSeconds)) {
	exit 11
}

$screenshotArgs = @()
if (-not [string]::IsNullOrWhiteSpace($script:ActiveSerial)) {
	$screenshotArgs += @("-s", $script:ActiveSerial)
}
$screenshotArgs += @("exec-out", "screencap", "-p")
$screenshotResult = Invoke-NativeBytes $AdbBin $screenshotArgs
if ($screenshotResult.Status -ne 0) {
	$screenshotResult.Output | ForEach-Object { Write-Output $_ }
	Write-Step "ADB_SCREENSHOT_FAILED=$($screenshotResult.Status)"
	exit 6
}
[System.IO.File]::WriteAllBytes($resolvedScreenshotPath, $screenshotResult.Bytes)

$screenshotItem = Get-Item -LiteralPath $resolvedScreenshotPath -ErrorAction SilentlyContinue
if ($screenshotItem -eq $null -or $screenshotItem.Length -le 0) {
	Write-Step "ADB_SCREENSHOT_EMPTY=$resolvedScreenshotPath"
	exit 7
}
if ($screenshotItem.Length -lt $MinScreenshotBytes) {
	Write-Step "ADB_SCREENSHOT_TOO_SMALL bytes=$($screenshotItem.Length)"
	exit 7
}
Write-Step "ADB_SCREENSHOT_OK bytes=$($screenshotItem.Length)"

$logcat = Invoke-Adb @("logcat", "-d", "-t", "$LogcatLines")
if ($logcat.Status -ne 0) {
	Write-Step "ADB_LOGCAT_FAILED=$($logcat.Status)"
	exit 8
}
$logText = $logcat.Output -join "`n"
if ($logText -match "FATAL EXCEPTION|E AndroidRuntime|SCRIPT ERROR|Parse Error|Compile Error") {
	Write-Step "ADB_STRICT_LOG_ERROR_FOUND"
	exit 9
}

Write-Step "ADB_SMOKE_CAPTURE_CLEAN"
