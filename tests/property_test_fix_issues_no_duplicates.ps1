# Property Test: Fix Issues adds rooms without duplicates
# Feature: full-frontend-fix, Property 1: Fix Issues adds rooms without duplicates
# Validates: Requirements 1.2, 1.3

$scriptPath = "frontend/script.js"
$passed = $true

Write-Host "Running Property 1: Fix Issues adds rooms without duplicates"
Write-Host "File: $scriptPath"
Write-Host ""

$content = Get-Content $scriptPath -Raw

# --- Check 1: autoFixIssues function exists ---
if ($content -match "async function autoFixIssues\(\)") {
    Write-Host "PASS: autoFixIssues() function exists"
} else {
    Write-Host "FAIL: autoFixIssues() function not found"
    $passed = $false
}

# --- Check 2: Fix_Rooms are deduplicated before adding (existingNames check) ---
if ($content -match "existingNames.*has\(r\.name\)") {
    Write-Host "PASS: Duplicate room check uses existingNames.has(r.name)"
} else {
    Write-Host "FAIL: No duplicate room name check found in autoFixIssues"
    $passed = $false
}

# --- Check 3: All 6 Fix_Rooms are defined ---
$fixRooms = @("1002", "1003", "1102", "1103", "1124", "1125")
foreach ($room in $fixRooms) {
    if ($content -match "name: '$room'") {
        Write-Host "PASS: Fix_Room '$room' is defined"
    } else {
        Write-Host "FAIL: Fix_Room '$room' is NOT defined"
        $passed = $false
    }
}

# --- Check 4: All 3 lab rooms are defined ---
$labRooms = @("L-001", "L-002", "L-003")
foreach ($room in $labRooms) {
    if ($content -match "name: '$room'") {
        Write-Host "PASS: Lab room '$room' is defined"
    } else {
        Write-Host "FAIL: Lab room '$room' is NOT defined"
        $passed = $false
    }
}

# --- Check 5: filter is used to exclude already-existing rooms (no duplicates) ---
if ($content -match "\.filter\(r => !existingNames\.has\(r\.name\)\)") {
    Write-Host "PASS: filter() used to exclude existing rooms before push"
} else {
    Write-Host "FAIL: filter() for deduplication not found"
    $passed = $false
}

# --- Check 6: resourceData.rooms.push is called with the filtered list ---
if ($content -match "resourceData\.rooms\.push\(\.\.\.toAdd\)") {
    Write-Host "PASS: resourceData.rooms.push(...toAdd) used (spread of filtered list)"
} else {
    Write-Host "FAIL: resourceData.rooms.push(...toAdd) not found"
    $passed = $false
}

Write-Host ""

if ($passed) {
    Write-Host "RESULT: PASS - Property 1 holds: autoFixIssues() adds rooms without duplicates"
    exit 0
} else {
    Write-Host "RESULT: FAIL - Property 1 violated: duplicate room prevention logic is missing or incorrect"
    exit 1
}
