param(
    [string]$ProtoFile = "server/mirror-shared/proto/mirror.proto",
    [string]$OutDir = "lib/features/mirror/grpc_generated"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoPath {
    param([string]$RelativePath)

    $root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    return [System.IO.Path]::GetFullPath((Join-Path $root $RelativePath))
}

function Test-CommandAvailable {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

function Get-ProtocExecutable {
    $systemProtoc = Get-Command protoc -ErrorAction SilentlyContinue
    if ($systemProtoc) {
        return $systemProtoc.Source
    }

    return Install-LocalProtoc
}

function Install-LocalProtoc {
    $repoRoot = Resolve-RepoPath '.'
    $toolsDir = Join-Path -Path $repoRoot -ChildPath '.tools'
    $protocDir = Join-Path -Path $toolsDir -ChildPath 'protoc'
    $binDir = Join-Path -Path $protocDir -ChildPath 'bin'
    $protocExe = Join-Path -Path $binDir -ChildPath 'protoc.exe'

    if (Test-Path -Path $protocExe) {
        return $protocExe
    }

    if (-not (Test-Path -Path $toolsDir)) {
        New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    }

    $version = if ($env:PROTOC_VERSION) { $env:PROTOC_VERSION } else { '34.1' }
    $zipName = "protoc-$version-win64.zip"
    $downloadUrl = "https://github.com/protocolbuffers/protobuf/releases/download/v$version/$zipName"
    $zipPath = Join-Path -Path $toolsDir -ChildPath $zipName

    Write-Host "Downloading protoc $version from $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

    if (Test-Path -Path $protocDir) {
        Remove-Item -Path $protocDir -Recurse -Force
    }

    Expand-Archive -Path $zipPath -DestinationPath $protocDir -Force

    if (-not (Test-Path -Path $protocExe)) {
        throw "Downloaded protoc archive did not contain expected executable: $protocExe"
    }

    return $protocExe
}

$protoPath = Resolve-RepoPath $ProtoFile
$outPath = Resolve-RepoPath $OutDir
$protoRoot = Split-Path -Path $protoPath -Parent

if (-not (Test-Path -Path $protoPath)) {
    throw "Proto file not found: $protoPath"
}

if (-not (Test-Path -Path $outPath)) {
    New-Item -ItemType Directory -Path $outPath -Force | Out-Null
}

Test-CommandAvailable -Name "dart"
$protocCmd = Get-ProtocExecutable

Write-Host "Ensuring protoc Dart plugin is available..."
dart pub global activate protoc_plugin | Out-Host

$pubCache = Join-Path -Path (Join-Path -Path (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Pub') -ChildPath 'Cache') -ChildPath 'bin'
$pluginCmd = Join-Path $pubCache "protoc-gen-dart.bat"
if (-not (Test-Path -Path $pluginCmd)) {
    $pluginCmd = Join-Path $pubCache "protoc-gen-dart"
}

if (-not (Test-Path -Path $pluginCmd)) {
    throw "Unable to locate protoc Dart plugin in Pub cache: $pubCache"
}

Write-Host "Generating Dart gRPC code from $protoPath"

$protocArgs = @(
    ('--proto_path={0}' -f $protoRoot)
    ('--dart_out=grpc:{0}' -f $outPath)
    ('--plugin=protoc-gen-dart={0}' -f $pluginCmd)
    $protoPath
)

& $protocCmd @protocArgs
if ($LASTEXITCODE -ne 0) {
    throw "protoc failed with exit code $LASTEXITCODE"
}

Write-Host "Done. Generated files in $outPath"
