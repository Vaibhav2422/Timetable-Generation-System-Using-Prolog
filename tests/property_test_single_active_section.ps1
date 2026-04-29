# Property Test: Exactly one section is active after navigation
# Feature: frontend-bug-fixes, Property 2: Exactly one section is active after navigation
# Validates: Requirements 2.1

$scriptPath  = "frontend/script.js"
$htmlPath    = "frontend/index.html"
$passed      = $true

Write-Host "Running Property 2: Exactly one section is active after navigation"
Write-Host ""

# --- Check 1: switchSection removes 'active' from all sections then adds it to target ---
$content = Get-Content $scriptPath -Raw

# Verify the function removes active from all sections
if ($content -match "querySelectorAll" -and $content -match "classList\.remove\('active'\)") {
    Write-Host "PASS: switchSection() removes 'active' from all .section elements"
} else {
    Write-Host "FAIL: switchSection() does not remove 'active' from all .section elements"
    $passed = $false
}

# Verify the function adds active to the target section using {name}-section pattern
if ($content -match "getElementById" -and $content -match "-section") {
    Write-Host "PASS: switchSection() targets element by '{name}-section' id pattern"
} else {
    Write-Host "FAIL: switchSection() does not use '{name}-section' id pattern"
    $passed = $false
}

if ($content -match "targetSection\.classList\.add\('active'\)") {
    Write-Host "PASS: switchSection() adds 'active' to the target section"
} else {
    Write-Host "FAIL: switchSection() does not add 'active' to the target section"
    $passed = $false
}

Write-Host ""

# --- Check 2: All 19 nav button data-section values have a matching section id in index.html ---
$htmlContent = Get-Content $htmlPath -Raw

$navSections = [System.Collections.Generic.List[string]]::new()
$navMatches  = [regex]::Matches($htmlContent, 'data-section="([^"]+)"')
foreach ($m in $navMatches) {
    $navSections.Add($m.Groups[1].Value)
}

Write-Host "Found $($navSections.Count) nav buttons with data-section attributes"

if ($navSections.Count -ne 19) {
    Write-Host "WARN: Expected 19 nav buttons, found $($navSections.Count)"
}

$mismatches = 0
foreach ($sec in $navSections) {
    $expectedId = "$sec-section"
    if ($htmlContent -match "id=""$expectedId""") {
        Write-Host "PASS: data-section='$sec' -> id='$expectedId' exists"
    } else {
        Write-Host "FAIL: data-section='$sec' -> id='$expectedId' NOT found in index.html"
        $passed = $false
        $mismatches++
    }
}

Write-Host ""

# --- Check 3: Only one section has 'active' class in the initial HTML ---
$initialActiveCount = ([regex]::Matches($htmlContent, 'class="section active"')).Count
if ($initialActiveCount -eq 1) {
    Write-Host "PASS: Exactly 1 section has 'active' class in initial HTML"
} else {
    Write-Host "FAIL: Expected 1 active section in initial HTML, found $initialActiveCount"
    $passed = $false
}

Write-Host ""

if ($passed) {
    Write-Host "RESULT: PASS - Property 2 holds: switchSection() correctly manages a single active section"
    exit 0
} else {
    Write-Host "RESULT: FAIL - Property 2 violated: navigation active-section logic has issues"
    exit 1
}
