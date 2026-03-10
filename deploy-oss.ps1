param(
    [Parameter(Mandatory = $true)]
    [string]$Bucket,

    [string]$Prefix = "",

    [string]$Endpoint = "",

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Test-Ossutil {
    $cmd = Get-Command ossutil -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "未找到 ossutil。请先安装并配置后重试。"
    }
}

function Join-OssPath {
    param(
        [string]$BucketName,
        [string]$ObjectPrefix
    )

    if ([string]::IsNullOrWhiteSpace($ObjectPrefix)) {
        return "oss://$BucketName/"
    }

    $normalized = $ObjectPrefix.Trim('/').Trim()
    return "oss://$BucketName/$normalized/"
}

Test-Ossutil

$target = Join-OssPath -BucketName $Bucket -ObjectPrefix $Prefix
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "项目目录: $projectRoot"
Write-Host "目标路径: $target"

$arguments = @("cp", "-r", ".", $target, "--update", "--exclude", ".git/*")

if (-not [string]::IsNullOrWhiteSpace($Endpoint)) {
    $arguments += @("--endpoint", $Endpoint)
}

if ($DryRun) {
    $arguments += "--dry-run"
}

Push-Location $projectRoot
try {
    & ossutil @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ossutil 执行失败，退出码: $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host "上传完成。"
