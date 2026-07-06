param(
	[string]$RootDir = (Get-Location).Path,
	[string]$Manifest = "tests/test_manifest_mvp.txt",
	[string]$GodotBin = "godot.cmd",
	[string]$LogFile = (Join-Path (Join-Path (Get-Location).Path "tmp") "wanguxingtu-mainline-tests.log"),
	[switch]$EnableGodotCrashHandler
)

$ErrorActionPreference = "Stop"

Set-Location $RootDir
$TmpDir = Join-Path $RootDir "tmp"
New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null
Set-Content -Path $LogFile -Value "" -Encoding UTF8

function Write-Log {
	param([string]$Message)
	$Message | Tee-Object -FilePath $LogFile -Append
}

if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
	Write-Log "MANIFEST_MISSING=$Manifest"
	exit 2
}

$tests = Get-Content -Encoding UTF8 -LiteralPath $Manifest |
	ForEach-Object { $_.Trim() } |
	Where-Object { $_ -and -not $_.StartsWith("#") }

if ($tests.Count -eq 0) {
	Write-Log "MANIFEST_EMPTY=$Manifest"
	exit 2
}

Write-Log "RUNNING_TEST_COUNT=$($tests.Count)"
foreach ($testPath in $tests) {
	if (-not (Test-Path -LiteralPath $testPath -PathType Leaf)) {
		Write-Log "TEST_FILE_MISSING=$testPath"
		exit 3
	}

	Write-Log "== $testPath =="
	$runId = [guid]::NewGuid().ToString("N")
	$stdoutFile = Join-Path $TmpDir ("wanguxingtu-test-stdout-{0}.log" -f $runId)
	$stderrFile = Join-Path $TmpDir ("wanguxingtu-test-stderr-{0}.log" -f $runId)
	$godotLogFile = Join-Path $TmpDir ("wanguxingtu-godot-{0}.log" -f $runId)
	$godotArgs = @("--headless", "--path", $RootDir, "--log-file", $godotLogFile)
	if (-not $EnableGodotCrashHandler) {
		$godotArgs += "--disable-crash-handler"
	}
	$godotArgs += @("--script", "res://$testPath")
	$process = Start-Process -FilePath $GodotBin `
		-ArgumentList $godotArgs `
		-NoNewWindow `
		-Wait `
		-PassThru `
		-RedirectStandardOutput $stdoutFile `
		-RedirectStandardError $stderrFile
	$status = $process.ExitCode
	$output = @()
	if (Test-Path -LiteralPath $stdoutFile) {
		$output += Get-Content -Encoding UTF8 -LiteralPath $stdoutFile
		Remove-Item -LiteralPath $stdoutFile -Force
	}
	if (Test-Path -LiteralPath $stderrFile) {
		$output += Get-Content -Encoding UTF8 -LiteralPath $stderrFile
		Remove-Item -LiteralPath $stderrFile -Force
	}
	if (Test-Path -LiteralPath $godotLogFile) {
		$output += Get-Content -Encoding UTF8 -LiteralPath $godotLogFile
		Remove-Item -LiteralPath $godotLogFile -Force
	}
	$output | Tee-Object -FilePath $LogFile -Append
	if ($status -ne 0) {
		Write-Log "TEST_EXIT_FAILED=$testPath status=$status"
		exit $status
	}
}

$content = Get-Content -Raw -Encoding UTF8 -LiteralPath $LogFile
if ($content -match "SCRIPT ERROR|Parse Error|Compile Error") {
	Write-Log "GODOT_STRICT_ERROR_FOUND"
	exit 4
}

Write-Log "MVP_MANIFEST_CLEAN"
