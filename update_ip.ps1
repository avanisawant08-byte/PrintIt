# Auto IP Updater for Print It App
# Run this script whenever you change WiFi networks

$apiClientPath = ".\print_it_app\lib\core\api\api_client.dart"

# Get the active WiFi IP address
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "169.*" -and
    $_.IPAddress -ne "127.0.0.1" -and
    $_.PrefixOrigin -eq "Dhcp"
} | Select-Object -First 1).IPAddress

if (-not $ip) {
    Write-Host "Could not detect your IP address. Are you connected to WiFi?" -ForegroundColor Red
    exit 1
}

Write-Host "Detected IP: $ip" -ForegroundColor Green

# Read the file content
$content = Get-Content $apiClientPath -Raw

# Replace the baseUrl line using a simple string replacement
$pattern = "static const String baseUrl = 'http://[\d\.]+:3000/api';"
$replacement = "static const String baseUrl = 'http://" + $ip + ":3000/api';"
$newContent = [regex]::Replace($content, $pattern, $replacement)

# Write back
[System.IO.File]::WriteAllText((Resolve-Path $apiClientPath), $newContent)

Write-Host "Updated api_client.dart with: http://$ip`:3000/api" -ForegroundColor Green
Write-Host ""
Write-Host "Now run 'flutter run' in your print_it_app directory!" -ForegroundColor Cyan
