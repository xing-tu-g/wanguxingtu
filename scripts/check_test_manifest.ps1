param(
	[string]$RootDir = (Get-Location).Path,
	[string]$Manifest = "tests/test_manifest_mvp.txt",
	[string]$TestsDir = "tests"
)

$ErrorActionPreference = "Stop"

Set-Location $RootDir

function Convert-ToRepoPath {
	param([string]$Path)
	return ($Path -replace "\\", "/")
}

function Get-TestSortKey {
	param([string]$Path)
	$name = [System.IO.Path]::GetFileName($Path)
	if ($name -match "^m([0-9]+)([a-z]?)_") {
		return "{0:D4}{1}_{2}" -f [int]$Matches[1], $Matches[2], $Path
	}
	return $Path
}

if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
	Write-Output "MANIFEST_MISSING=$Manifest"
	exit 2
}

if (-not (Test-Path -LiteralPath $TestsDir -PathType Container)) {
	Write-Output "TESTS_DIR_MISSING=$TestsDir"
	exit 2
}

$manifestTests = Get-Content -Encoding UTF8 -LiteralPath $Manifest |
	ForEach-Object { $_.Trim() } |
	Where-Object { $_ -and -not $_.StartsWith("#") } |
	ForEach-Object { Convert-ToRepoPath $_ }

$testFiles = Get-ChildItem -LiteralPath $TestsDir -Filter "*.gd" -File |
	ForEach-Object { Convert-ToRepoPath (Join-Path $TestsDir $_.Name) } |
	Sort-Object { Get-TestSortKey $_ }

Write-Output "MANIFEST_TEST_COUNT=$($manifestTests.Count)"
Write-Output "TEST_FILE_COUNT=$($testFiles.Count)"

$hasFailure = $false

$notInManifest = @($testFiles | Where-Object { $manifestTests -notcontains $_ })
foreach ($testPath in $notInManifest) {
	Write-Output "TEST_NOT_IN_MANIFEST=$testPath"
	$hasFailure = $true
}

$missingFiles = @($manifestTests | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
foreach ($testPath in $missingFiles) {
	Write-Output "MANIFEST_FILE_MISSING=$testPath"
	$hasFailure = $true
}

$expectedOrder = @($manifestTests | Sort-Object { Get-TestSortKey $_ })
for ($index = 0; $index -lt $manifestTests.Count; $index++) {
	if ($manifestTests[$index] -ne $expectedOrder[$index]) {
		Write-Output "MANIFEST_ORDER_INVALID=index:$index expected:$($expectedOrder[$index]) actual:$($manifestTests[$index])"
		$hasFailure = $true
		break
	}
}

if ($hasFailure) {
	exit 1
}

Write-Output "TEST_MANIFEST_SYNC_CLEAN"
