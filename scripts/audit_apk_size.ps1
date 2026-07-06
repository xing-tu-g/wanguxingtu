param(
	[string]$ApkPath = "builds/wanguxingtu-battle-polish-v1-debug.apk",
	[int]$Top = 40
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ApkPath -PathType Leaf)) {
	Write-Output "APK_MISSING=$ApkPath"
	exit 2
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$apkFullPath = (Resolve-Path -LiteralPath $ApkPath).Path
$zip = [System.IO.Compression.ZipFile]::OpenRead($apkFullPath)
try {
	$totalRaw = 0L
	$totalZip = 0L
	$groups = @{}
	foreach ($entry in $zip.Entries) {
		$totalRaw += $entry.Length
		$totalZip += $entry.CompressedLength
		$parts = $entry.FullName -split "/"
		$key = $parts[0]
		if ($parts.Count -gt 1 -and $parts[0] -eq "assets") {
			$key = "assets/" + $parts[1]
		}
		if (-not $groups.ContainsKey($key)) {
			$groups[$key] = [pscustomobject]@{ Count = 0; Raw = 0L; Zip = 0L }
		}
		$groups[$key].Count += 1
		$groups[$key].Raw += $entry.Length
		$groups[$key].Zip += $entry.CompressedLength
	}

	Write-Output ("APK_SIZE_BYTES={0}" -f (Get-Item -LiteralPath $apkFullPath).Length)
	Write-Output ("APK_RAW_CONTENT_MB={0:N2}" -f ($totalRaw / 1MB))
	Write-Output ("APK_ZIP_CONTENT_MB={0:N2}" -f ($totalZip / 1MB))
	Write-Output "APK_SIZE_GROUPS"
	$groups.GetEnumerator() |
		Sort-Object { $_.Value.Zip } -Descending |
		Select-Object -First $Top |
		ForEach-Object {
			Write-Output ("{0}`tcount={1}`traw_mb={2:N2}`tzip_mb={3:N2}" -f $_.Key, $_.Value.Count, ($_.Value.Raw / 1MB), ($_.Value.Zip / 1MB))
		}

	Write-Output "APK_SIZE_TOP_FILES"
	$zip.Entries |
		Sort-Object CompressedLength -Descending |
		Select-Object -First $Top |
		ForEach-Object {
			Write-Output ("{0}`traw_mb={1:N2}`tzip_mb={2:N2}" -f $_.FullName, ($_.Length / 1MB), ($_.CompressedLength / 1MB))
		}
	Write-Output "APK_SIZE_AUDIT_CLEAN"
}
finally {
	$zip.Dispose()
}
