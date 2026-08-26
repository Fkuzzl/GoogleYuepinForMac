param(
    [switch]$LiveEndpoint
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { $script:Failures.Add($Message) }
}

$requiredFiles = @(
    'Package.swift',
    'GoogleYuepinForMac.xcodeproj/project.pbxproj',
    'GoogleYuepinForMac.xcodeproj/xcshareddata/xcschemes/GoogleYuepinForMac.xcscheme',
    'GoogleYuepinForMac/Info.plist',
    'GoogleYuepinForMac/GoogleYuepinForMac.entitlements',
    'GoogleYuepinForMac/PrivacyInfo.xcprivacy',
    'GoogleYuepinForMac/GoogleYuepinInputController.swift',
    'Sources/GoogleYuepinCore/CompositionEngine.swift',
    'Sources/GoogleYuepinCore/GoogleResponseParser.swift',
    'Tests/GoogleYuepinCoreTests/Fixtures/nei-success.json',
    'Scripts/build-local.sh',
    'Scripts/test-on-mac.sh',
    'Scripts/install-local.sh'
)

foreach ($relativePath in $requiredFiles) {
    Assert-True (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativePath)) "Missing required file: $relativePath"
}

$xmlFiles = @(
    'GoogleYuepinForMac/Info.plist',
    'GoogleYuepinForMac/GoogleYuepinForMac.entitlements',
    'GoogleYuepinForMac/PrivacyInfo.xcprivacy',
    'GoogleYuepinForMac.xcodeproj/xcshareddata/xcschemes/GoogleYuepinForMac.xcscheme',
    'GoogleYuepinForMac/Resources/InputSourceIcon.svg'
)
foreach ($relativePath in $xmlFiles) {
    try {
        [xml](Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot $relativePath)) | Out-Null
    } catch {
        $Failures.Add("Invalid XML: $relativePath ($($_.Exception.Message))")
    }
}

$fixtureFiles = Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'Tests/GoogleYuepinCoreTests/Fixtures') -Filter '*.json'
foreach ($fixture in $fixtureFiles) {
    try {
        Get-Content -Raw -LiteralPath $fixture.FullName | ConvertFrom-Json | Out-Null
    } catch {
        $Failures.Add("Invalid JSON fixture: $($fixture.Name)")
    }
}

$infoText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'GoogleYuepinForMac/Info.plist')
Assert-True ($infoText.Contains('<string>yue-Hant</string>')) 'Info.plist does not declare yue-Hant.'
Assert-True ($infoText.Contains('<string>Hant</string>')) 'Info.plist does not declare the Hant repertoire.'
Assert-True ($infoText.Contains('local.googleyuepinformac.inputmethod.GoogleYuepinIM')) 'Input mode ID is missing from Info.plist.'
Assert-True (-not $infoText.Contains('<key>TISInputSourceID</key><string>local.googleyuepinformac.inputmethod</string>')) 'Info.plist contains a conflicting top-level input-source ID.'
Assert-True ($infoText.Contains('<key>LSUIElement</key><true/>')) 'Info.plist does not mark the input method as a UI agent.'
Assert-True ($infoText.Contains('<key>LSBackgroundOnly</key><false/>')) 'Info.plist incorrectly marks the input method as background-only.'
Assert-True ($infoText.Contains('<key>InputMethodServerControllerClass</key><string>GoogleYuepinInputController</string>')) 'Info.plist has an unexpected InputMethodKit controller class.'
Assert-True ($infoText.Contains('<key>CFBundleVersion</key><string>$(CURRENT_PROJECT_VERSION)</string>')) 'Info.plist does not use Xcode build versioning.'

foreach ($locale in @('en', 'zh-Hant')) {
    $localizedInfoPath = Join-Path $ProjectRoot "GoogleYuepinForMac/$locale.lproj/InfoPlist.strings"
    Assert-True (Test-Path -LiteralPath $localizedInfoPath) "$locale input-source localization is missing."
    if (Test-Path -LiteralPath $localizedInfoPath) {
        $localizedInfoText = Get-Content -Raw -LiteralPath $localizedInfoPath
        Assert-True ($localizedInfoText.Contains('"local.googleyuepinformac.inputmethod.GoogleYuepinIM" = "Google粵拼forMac";')) "$locale input-mode name is missing."
    }
}

$entitlementsText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'GoogleYuepinForMac/GoogleYuepinForMac.entitlements')
Assert-True ($entitlementsText.Contains('com.apple.security.network.client')) 'Network client entitlement is missing.'

$installerText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'Scripts/install-local.sh')
$readmeText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'README.md')
Assert-True ($installerText.Contains('destination_directory="/Library/Input Methods"')) 'Local installer does not use the system input-method directory.'
Assert-True ($installerText.Contains('legacy_user_app="${HOME}/Library/Input Methods/GoogleYuepinForMac.app"')) 'Local installer does not clean up the earlier user-local copy.'
Assert-True ($installerText.Contains('/usr/bin/sudo /usr/sbin/chown -R root:wheel "${destination_app}"')) 'System-wide input method is not secured with root ownership.'
Assert-True ($installerText.Contains('macOS did not discover the Apple Development-signed input method.')) 'Installer does not diagnose Personal Team TIS rejection.'

$projectText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'GoogleYuepinForMac.xcodeproj/project.pbxproj')
Assert-True ($projectText.Contains('CODE_SIGN_IDENTITY = "Apple Development";')) 'Xcode target does not use Apple Development signing.'
Assert-True ($projectText.Contains('CODE_SIGN_STYLE = Automatic;')) 'Xcode target does not use automatic signing.'
Assert-True ($projectText.Contains('CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO;')) 'Xcode target still injects development-only base entitlements.'
Assert-True ($readmeText.Contains('Developer ID-signed and notarized build')) 'README does not document the signing requirement for affected Macs.'
Assert-True (-not $projectText.Contains('CODE_SIGN_IDENTITY = "-";')) 'Xcode target still contains an ad-hoc signing identity.'
Assert-True ($entitlementsText.Contains('com.apple.security.temporary-exception.mach-register.global-name')) 'InputMethodKit Mach entitlement is missing.'
Assert-True ($entitlementsText.Contains('local.googleyuepinformac.inputmethod_Connection')) 'InputMethodKit connection entitlement is inconsistent.'

$projectText = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'GoogleYuepinForMac.xcodeproj/project.pbxproj')
Assert-True ($projectText.Contains('PRODUCT_BUNDLE_IDENTIFIER = local.googleyuepinformac.inputmethod;')) 'Xcode bundle ID is inconsistent.'
Assert-True ($projectText.Contains('MACOSX_DEPLOYMENT_TARGET = 15.0;')) 'Xcode deployment target is not macOS 15.0.'
Assert-True ($projectText.Contains('ARCHS = arm64;')) 'Xcode target is not restricted to Apple Silicon.'

if ($LiveEndpoint) {
    try {
        $uri = 'https://inputtools.google.com/request?text=nei&itc=yue-hant-t-i0-und&num=6&ie=utf-8&oe=utf-8'
        $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 10
        $bytes = $webResponse.RawContentStream.ToArray()
        $response = [System.Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
        Assert-True ($response[0] -eq 'SUCCESS') 'Google Input Tools did not return SUCCESS.'
        $leadingCandidate = [string]$response[1][0][1][0]
        Assert-True (($leadingCandidate.Length -eq 1) -and ([int][char]$leadingCandidate[0] -eq 0x4F60)) 'The live sample no longer returns U+4F60 as the leading candidate for nei.'
    } catch {
        $Failures.Add("Live Google Input Tools check failed: $($_.Exception.Message)")
    }
}

if ($Failures.Count -gt 0) {
    $Failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Repository structure: PASS"
Write-Output "XML and JSON syntax: PASS"
Write-Output "Input-source metadata: PASS"
Write-Output "Xcode target consistency: PASS"
if ($LiveEndpoint) { Write-Output "Google Input Tools contract: PASS" }
Write-Output "Swift/Xcode compilation: NOT RUN (requires macOS with Xcode)"
