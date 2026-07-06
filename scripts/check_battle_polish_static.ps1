param(
	[string]$RootDir = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $RootDir
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
	param([string]$Message)
	$failures.Add($Message) | Out-Null
}

function Assert-True {
	param(
		[bool]$Condition,
		[string]$Message
	)
	if (-not $Condition) {
		Add-Failure $Message
	}
}

function Resolve-ResPath {
	param([string]$Path)
	if ($Path.StartsWith("res://")) {
		return (Join-Path $RootDir $Path.Substring(6))
	}
	return (Join-Path $RootDir $Path)
}

$coreHeroes = @(
	"zhaoyun",
	"guanyu",
	"zhangfei",
	"lvbu",
	"zhugeliang",
	"caocao",
	"dianwei",
	"zhouyu",
	"sunce",
	"diaochan"
)

$heroes = Get-Content -Raw -Encoding UTF8 -LiteralPath "data/heroes.json" | ConvertFrom-Json
$skills = Get-Content -Raw -Encoding UTF8 -LiteralPath "data/skills.json" | ConvertFrom-Json
$heroesById = @{}
$skillsById = @{}
foreach ($hero in $heroes) { $heroesById[$hero.id] = $hero }
foreach ($skill in $skills) { $skillsById[$skill.id] = $skill }

foreach ($heroId in $coreHeroes) {
	Assert-True $heroesById.ContainsKey($heroId) "CORE_HERO_MISSING=$heroId"
	if (-not $heroesById.ContainsKey($heroId)) { continue }
	$hero = $heroesById[$heroId]
	foreach ($field in @("hero_master", "battle_idle", "battle_attack", "battle_skill")) {
		$value = [string]$hero.$field
		Assert-True (-not [string]::IsNullOrWhiteSpace($value)) "CORE_HERO_FIELD_EMPTY=$heroId.$field"
		if (-not [string]::IsNullOrWhiteSpace($value)) {
			Assert-True (Test-Path -LiteralPath (Resolve-ResPath $value) -PathType Leaf) "CORE_HERO_ART_MISSING=$heroId.$field"
		}
	}
	$skillIds = @($hero.skill_ids)
	Assert-True ($skillIds.Count -gt 0) "CORE_HERO_SKILL_IDS_EMPTY=$heroId"
	foreach ($skillId in $skillIds) {
		Assert-True $skillsById.ContainsKey([string]$skillId) "CORE_HERO_SKILL_DEF_MISSING=$heroId.$skillId"
	}
}

Assert-True (Test-Path -LiteralPath "scripts/tools/capture_core_skill_screens.gd" -PathType Leaf) "CORE_SKILL_CAPTURE_SCRIPT_MISSING"
Assert-True (Test-Path -LiteralPath "scripts/audit_apk_size.ps1" -PathType Leaf) "APK_AUDIT_SCRIPT_MISSING"

$exportPreset = Get-Content -Raw -Encoding UTF8 -LiteralPath "export_presets.cfg"
foreach ($requiredFilter in @(
	"tmp/**/*",
	"image2.0/**/*",
	"assets/heroes/*/*.source.*",
	"assets/heroes/*/*.rejected*",
	"assets/heroes/*/*.v*.png.import",
	".godot/imported/*.source.*",
	".godot/imported/*.rejected*"
)) {
	Assert-True ($exportPreset.Contains($requiredFilter)) "EXPORT_FILTER_MISSING=$requiredFilter"
}

$heroImports = Get-ChildItem -LiteralPath "assets/heroes" -Recurse -Filter "*.png.import"
$heroMasterCount = 0
$battleCount = 0
foreach ($importFile in $heroImports) {
	$text = Get-Content -Raw -Encoding UTF8 -LiteralPath $importFile.FullName
	$match = [regex]::Match($text, "process/size_limit=(\d+)")
	if (-not $match.Success) {
		Add-Failure "IMPORT_SIZE_LIMIT_MISSING=$($importFile.FullName)"
		continue
	}
	$limit = [int]$match.Groups[1].Value
	if ($importFile.Name -like "battle_*.png.import" -or $importFile.Name -like "battle_*.v*.png.import" -or $importFile.Name -like "battle_*.source*.png.import" -or $importFile.Name -like "battle_*.rejected*.png.import") {
		$battleCount += 1
		Assert-True ($limit -eq 768) "BATTLE_IMPORT_SIZE_LIMIT_INVALID=$($importFile.FullName):$limit"
	}
	elseif ($importFile.Name -like "hero_master*.png.import") {
		$heroMasterCount += 1
		Assert-True ($limit -eq 1024) "MASTER_IMPORT_SIZE_LIMIT_INVALID=$($importFile.FullName):$limit"
	}
}

Assert-True ($heroMasterCount -gt 0) "MASTER_IMPORTS_NOT_FOUND"
Assert-True ($battleCount -gt 0) "BATTLE_IMPORTS_NOT_FOUND"

if ($failures.Count -gt 0) {
	foreach ($failure in $failures) {
		Write-Output $failure
	}
	exit 1
}

Write-Output "CORE_SKILL_HERO_COUNT=$($coreHeroes.Count)"
Write-Output "HERO_IMPORT_MASTER_COUNT=$heroMasterCount"
Write-Output "HERO_IMPORT_BATTLE_COUNT=$battleCount"
Write-Output "BATTLE_POLISH_STATIC_CLEAN"
