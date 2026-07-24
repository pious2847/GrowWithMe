# Reconnects the phone to the dev backend WITHOUT a USB cable.
# Use after a reboot, or whenever the app shows the offline cloud icon.
#
# Requirements: phone and PC on the same network (phone hotspot or same Wi-Fi).
# One-time setup per USB session: `adb tcpip 5555` with the cable attached
# (already done — survives until the phone reboots).

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Candidate phone IPs: last known hotspot IP + common hotspot gateways.
$candidates = @('10.152.112.73', '192.168.43.1', '172.20.10.1')

Write-Host 'Looking for the phone on the network...'
$connected = $false
foreach ($ip in $candidates) {
    $result = & $adb connect "${ip}:5555" 2>&1
    if ("$result" -match 'connected') {
        Write-Host "Connected to phone at $ip" -ForegroundColor Green
        & $adb -s "${ip}:5555" reverse tcp:5000 tcp:5000 | Out-Null
        Write-Host 'Backend bridge (localhost:5000) is up.' -ForegroundColor Green
        $connected = $true
        break
    }
}

if (-not $connected) {
    Write-Host 'Phone not found. Check:' -ForegroundColor Yellow
    Write-Host ' 1. Phone and PC are on the same network (hotspot or Wi-Fi)'
    Write-Host " 2. Find the phone's IP: Settings > Hotspot (or Wi-Fi details)"
    Write-Host ' 3. Run: adb connect <phone-ip>:5555'
    Write-Host ' 4. If TCP mode expired (phone rebooted): plug cable once, run: adb tcpip 5555'
}
