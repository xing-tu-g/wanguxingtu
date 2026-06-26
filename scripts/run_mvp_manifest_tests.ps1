param(
	[string]$RootDir = (Get-Location).Path,
	[string]$Manifest = "tests/test_manifest_mvp.txt",
	[string]$GodotBin = "godot.cmd",
	[string]$LogFile = (Join-Path $env:TEMP "wanguxingtu-mainline-tests.log")
)

$ErrorActionPreference = "Stop"

Set-Location $RootDir
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
	$output = & $GodotBin --headless --path $RootDir --script "res://$testPath" 2>&1
	$status = $LASTEXITCODE
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
