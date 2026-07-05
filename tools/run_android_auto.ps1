$ErrorActionPreference = "Stop"

$devices = flutter devices --machine | ConvertFrom-Json
$androidDevices = @(
    $devices | Where-Object {
        $_.targetPlatform -like "android*" -or $_.platform -eq "android"
    }
)

if ($androidDevices.Count -eq 0) {
    throw "No Android device or emulator found. Start an emulator or plug in a phone, then try again."
}

$physicalDevices = @($androidDevices | Where-Object { $_.emulator -eq $false })
$emulators = @($androidDevices | Where-Object { $_.emulator -eq $true })

function Get-LanIp {
    $ip = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*" -and
            $_.PrefixOrigin -ne "WellKnown"
        } |
        Sort-Object InterfaceMetric |
        Select-Object -First 1 -ExpandProperty IPAddress

    if ([string]::IsNullOrWhiteSpace($ip)) {
        throw "Could not detect a LAN IPv4 address for the physical device."
    }
    return $ip
}

if ($physicalDevices.Count -gt 0) {
    $device = $physicalDevices[0]
    $hostIp = Get-LanIp
    Write-Host "Running on physical Android device: $($device.name) [$($device.id)]"
    Write-Host "Using backend host: $hostIp"
    flutter run -d $device.id --dart-define=DEV_SERVER_HOST=$hostIp @args
    exit $LASTEXITCODE
}

$device = $emulators[0]
Write-Host "Running on Android emulator: $($device.name) [$($device.id)]"
Write-Host "Using backend host: 10.0.2.2"
flutter run -d $device.id --dart-define=DEV_SERVER_HOST=10.0.2.2 @args
exit $LASTEXITCODE
