[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [Parameter(Mandatory = $true)]
    [string]$Module,

    [string]$AppCode
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path

$searchRoots = @(
    (Join-Path $resolvedRoot 'ems'),
    (Join-Path $resolvedRoot 'hbwork\src\ems')
) | Where-Object { Test-Path -LiteralPath $_ }

if (-not $searchRoots) {
    $searchRoots = @($resolvedRoot)
}

function Find-Files {
    param([string[]]$Patterns)

    Get-ChildItem -LiteralPath $searchRoots -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $path = $_.FullName
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
    $_ -match '\\src\\ems\\' -and $_ -match '\\index\.js$'
}

Write-Output "`n[Metadata/DDL candidates]"
$moduleFiles | Where-Object {
    $_ -match '\.(bmf|sql)$'
} | Select-Object -First 60

if ($AppCode) {
    Write-Output "`n[Files containing AppCode]"
    Get-ChildItem -LiteralPath $searchRoots -Recurse -File -Include *.xml,*.java,*.js,*.sql -ErrorAction SilentlyContinue |
        Select-String -SimpleMatch -Pattern $AppCode -List -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -Unique |
        Select-Object -First 80
}

Write-Output "`nRead-only inspection completed. Verify each candidate directly before editing."
