[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [Parameter(Mandatory = $true)]
    [string]$Module,

    [string]$AppCode,

    [string]$Scope
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path

$searchRoots = @()
if ($Scope) {
    $searchRoots = ($Scope -split '[;,]') | ForEach-Object {
        $_ = $_.Trim()
        if (-not $_) { return }
        $candidate = if ([System.IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $resolvedRoot $_ }
        if (Test-Path -LiteralPath $candidate) { (Resolve-Path -LiteralPath $candidate).Path }
    }
} else {
    $searchRoots = @($resolvedRoot)
}

if (-not $searchRoots) { throw 'No valid search roots were found.' }

function Find-Files {
    param([string[]]$Patterns)

    Get-ChildItem -LiteralPath $searchRoots -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $path = $_.FullName
            if ($path -match '\\(\.git|node_modules|dist|tools|target|out)\\') { return $false }
            foreach ($pattern in $Patterns) {
                if ($path -match $pattern) { return $true }
            }
            return $false
        } |
        Select-Object -ExpandProperty FullName -Unique
}

Write-Output "Root: $resolvedRoot"
Write-Output "Module: $Module"
if ($AppCode) { Write-Output "AppCode: $AppCode" }

$escapedModule = [regex]::Escape($Module)
$moduleFiles = Find-Files @($escapedModule)

Write-Output "`n[Module files]"
$moduleFiles | Select-Object -First 80

$configFiles = $moduleFiles | Where-Object {
    $_ -match '\\config\\(action|authorize|userdef)\\' -and $_ -match '\.xml$'
}

Write-Output "`n[Action/Authorize configuration]"
$configFiles

Write-Output "`n[Frontend entry/reference candidates]"
$moduleFiles | Where-Object {
    $_ -match '\\src\\' -and $_ -match '\\index\.js$'
}

Write-Output "`n[Metadata/DDL candidates]"
$moduleFiles | Where-Object {
    $_ -match '\.(bmf|sql)$'
} | Select-Object -First 60

if ($AppCode) {
    Write-Output "`n[Files containing AppCode]"
    Get-ChildItem -LiteralPath $searchRoots -Recurse -File -Include *.xml,*.java,*.js,*.sql -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\(\.git|node_modules|dist|tools|target|out)\\' } |
        Select-String -SimpleMatch -Pattern $AppCode -List -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -Unique |
        Select-Object -First 80
}

Write-Output "`nRead-only inspection completed. Verify each candidate directly before editing."
