# Auto IP Updater for Print It App
# Run this script whenever you change WiFi networks

$apiClientPath = ".\print_it_app\lib\core\api\api_client.dart"

# Get the active WiFi IP address
$ips = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "169.*" -and
    $_.IPAddress -ne "127.0.0.1"
})

if (-not $ips -or $ips.Count -eq 0) {
    Write-Host "Could not detect your IP address. Are you connected to WiFi?" -ForegroundColor Red
    exit 1
}

$ip = $ips[0].IPAddress
if ($ips.Count -gt 1) {
    Write-Host "Multiple IP addresses found:" -ForegroundColor Yellow
    for ($i=0; $i -lt $ips.Count; $i++) {
        Write-Host "  $($i+1). $($ips[$i].IPAddress) ($($ips[$i].InterfaceAlias))"
    }
    $selection = Read-Host "Enter the number of the IP to use (default 1)"
    if ([int]::TryParse($selection, [ref]$null) -and $selection -ge 1 -and $selection -le $ips.Count) {
        $ip = $ips[[int]$selection - 1].IPAddress
    }
}

Write-Host "Detected IP: $ip" -ForegroundColor Green

# Read the file content
$content = Get-Content $apiClientPath -Raw

# Replace currentBaseUrl line using regex matching any hostname or IP
$pattern = "static String currentBaseUrl = 'http://[^']+:3000/api';"
$replacement = "static String currentBaseUrl = 'http://" + $ip + ":3000/api';"
$newContent = [regex]::Replace($content, $pattern, $replacement)

# Write back
[System.IO.File]::WriteAllText((Resolve-Path $apiClientPath), $newContent)

Write-Host "Updated api_client.dart with: http://$ip`:3000/api" -ForegroundColor Green
Write-Host ""
Write-Host "Now run 'flutter run' in your print_it_app directory!" -ForegroundColor Cyan
