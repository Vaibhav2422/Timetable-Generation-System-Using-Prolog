# Property Test: Example dataset loads correct counts
# Feature: frontend-bug-fixes, Property 5: Example dataset loads correct counts
# Validates: Requirements 1.4, 5.1

$scriptPath = "frontend/script.js"
$passed = $true

Write-Host "Running Property 5: Example dataset loads correct counts"
Write-Host "File: $scriptPath"
Write-Host ""

# Expected counts reflect the expanded dataset (updated after task 1 expanded resources
# to fix room/timeslot shortages per requirements 1.2, 1.3, 1.4)
$expected = @{
    teachers  = 9
    subjects  = 11
    rooms     = 30
    timeslots = 45
    classes   = 8
}

# --- Check 1: Each resource type has the correct number of entries in loadExampleDataset ---
$idPatterns = @{
    teachers  = "id: 't\d"
    subjects  = "id: 's\d"
    rooms     = "id: 'r\d"
    timeslots = "id: 'slot\d"
    classes   = "id: 'c\d"
}

foreach ($type in $expected.Keys) {
    $pattern = $idPatterns[$type]
    $count = (Select-String -Path $scriptPath -Pattern $pattern).Count
    $exp   = $expected[$type]
    if ($count -eq $exp) {
        Write-Host "PASS: $type count = $count (expected $exp)"
    } else {
        Write-Host "FAIL: $type count = $count (expected $exp)"
        $passed = $false
    }
}

Write-Host ""

# --- Check 2: loadExampleDataset calls updateResourceCounts() ---
$content = Get-Content $scriptPath -Raw
if ($content -match "(?s)function loadExampleDataset\(\).*?updateResourceCounts\(\)") {
    Write-Host "PASS: loadExampleDataset() calls updateResourceCounts()"
} else {
    Write-Host "FAIL: loadExampleDataset() does NOT call updateResourceCounts()"
    $passed = $false
}

Write-Host ""

# --- Check 3: loadExampleDataset calls showNotification for success feedback ---
if ($content -match "(?s)function loadExampleDataset\(\).*?showNotification\('success'") {
    Write-Host "PASS: loadExampleDataset() calls showNotification('success', ...)"
} else {
    Write-Host "FAIL: loadExampleDataset() does NOT call showNotification('success', ...)"
    $passed = $false
}

Write-Host ""

if ($passed) {
    Write-Host "RESULT: PASS - Property 5 holds: loadExampleDataset() populates correct counts and updates UI"
    exit 0
} else {
    Write-Host "RESULT: FAIL - Property 5 violated: loadExampleDataset() has incorrect counts or missing calls"
    exit 1
}
