[CmdletBinding()]
param(
    [string]$Source = (Join-Path $PSScriptRoot 'review-notes.md'),
    [string]$TemplatePath = (Join-Path $PSScriptRoot 'templates\\eisvogel.tex'),
    [string]$Output = (Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist') 'ECE345-Final-Review.pdf')
)

function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Message
    )
    if (-not (Test-Path $Path)) {
        throw $Message
    }
}

function Enable-Tls12 {
    $current = [Net.ServicePointManager]::SecurityProtocol
    if (($current -band [Net.SecurityProtocolType]::Tls12) -eq 0) {
        [Net.ServicePointManager]::SecurityProtocol = $current -bor [Net.SecurityProtocolType]::Tls12
    }
}

function Get-TemplateCandidate {
    param([string]$PreferredPath)

    $candidates = @(
        $PreferredPath,
        [System.IO.Path]::ChangeExtension($PreferredPath, '.latex')
    )

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if (Test-Path $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Resolve-TemplatePath {
    param(
        [string]$TargetPath
    )
    $existing = Get-TemplateCandidate -PreferredPath $TargetPath
    if ($existing) {
        return $existing
    }

    Write-Host "Downloading Eisvogel template..."
    $templateDir = Split-Path $TargetPath -Parent
    New-Item -ItemType Directory -Force -Path $templateDir | Out-Null
    $uri = 'https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/main/eisvogel.tex'

    Enable-Tls12
    try {
        Invoke-WebRequest -Uri $uri -OutFile $TargetPath -UseBasicParsing -ErrorAction Stop
    }
    catch {
        throw "Failed to download Eisvogel template from $uri. Check your internet connection or download the file manually. Original error: $($_.Exception.Message)"
    }

    return (Resolve-Path -LiteralPath $TargetPath).Path
}

function Set-DirectorySafe {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

$sourcePath = (Resolve-Path $Source).Path
$templatePath = $TemplatePath
$outputPath = $Output
$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandoc) {
    throw "Pandoc is required but was not found in PATH."
}

$xelatex = Get-Command xelatex -ErrorAction SilentlyContinue
if (-not $xelatex) {
    Write-Warning "xelatex was not found. Make sure a LaTeX distribution is installed before running Pandoc."
}

$templateResolved = Resolve-TemplatePath -TargetPath $templatePath

$sourceDir = Split-Path $sourcePath -Parent
Assert-PathExists -Path $sourceDir -Message "Could not locate source directory: $sourceDir"

Set-DirectorySafe -Path (Split-Path $outputPath -Parent)

$pandocArgs = @(
    $sourcePath,
    '--from=markdown',
    "--template=$templateResolved",
    '--pdf-engine=xelatex',
    '--syntax-highlighting=idiomatic',
    "--output=$outputPath"
)

Write-Host "Generating PDF at $outputPath"
& $pandoc.Source @pandocArgs
if ($LASTEXITCODE -ne 0) {
    throw "Pandoc exited with code $LASTEXITCODE"
}

Write-Host 'Done.'
