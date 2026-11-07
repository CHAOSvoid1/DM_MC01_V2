# 下载 STM32C5 系列的 flash loader（*.xldr）
# 仅在使用"带 STM32C5 支持的 OpenOCD"（路线 B，见 README.md）时才需要。
# 用法：
#     pwsh -File tools\get_loader.ps1
#     pwsh -File tools\get_loader.ps1 -OutDir D:\some\where
param(
    [string]$OutDir = (Join-Path $PSScriptRoot 'stldr')
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Ref = 'a5f65bc64535cfa723e9d25f58d7ce23d0937aed'   # stm32c5xx-dfp 中带 C5 flash loader 的提交
$Api = "https://api.github.com/repos/STMicroelectronics/stm32c5xx-dfp/contents/Flash?ref=$Ref"
$Headers = @{ 'User-Agent' = 'mx2-flash-setup'; 'Accept' = 'application/vnd.github+json' }

Write-Host "列出 $Api ..." -ForegroundColor Cyan
$items = Invoke-RestMethod -Uri $Api -Headers $Headers -UseBasicParsing
$xldrs = @($items | Where-Object { $_.name -like '*.xldr' })

if ($xldrs.Count -eq 0) {
    Write-Host '没有找到 .xldr，仓库结构可能变了，请手动去 Flash/ 目录下载。' -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

foreach ($f in $xldrs) {
    $dest = Join-Path $OutDir $f.name
    Write-Host ("下载 {0} ({1:N0} KB)" -f $f.name, ($f.size / 1KB))
    Invoke-WebRequest -Uri $f.download_url -OutFile $dest -Headers @{ 'User-Agent' = 'mx2-flash-setup' } -UseBasicParsing
}

Write-Host ''
Write-Host ("完成，共 {0} 个文件 → {1}" -f $xldrs.Count, (Resolve-Path $OutDir)) -ForegroundColor Green
Write-Host '如果你用的 OpenOCD 版本需要显式指定 loader 路径，把上面的目录填到'
Write-Host 'tools\stm32c5_stlink.cfg 或 OpenOCD 的 stldr set_loader 命令里。'
