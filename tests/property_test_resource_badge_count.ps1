# Property Test: Resource badge count equals array length
# Feature: frontend-bug-fixes, Property 1: Resource badge count equals array length
# Validates: Requirements 1.1, 1.3

$scriptPath = "frontend/script.js"
$passed = $true

Write-Host "Running Property 1: Resource badge count equals array length"
Write-Host "File: $scriptPath"
Write-Host ""

# --- Check 1: updateResourceCounts sets badge textContent for all 5 types ---
$types = @("teachers", "subjects", "rooms", "timeslots", "classes")
foreach ($type in $types) {
    $pattern = "count-$type.*textContent\s*=\s*resourceData\.$type\.length"
    $match = Select-String -Path $scriptPath -Pattern $pattern
    if ($match) {
        Write-Host "PASS: Badge for '$type' is set from resourceData.$type.length"
    } else {
        Write-Host "FAIL: Badge for '$type' is NOT set from resourceData.$type.length"
        $passed = $false
    }
}

Write-Host ""

# --- Check 2: updateResourceCounts is called in all 5 form submit handlers ---
$content = Get-Content $scriptPath -Raw

# Extract each form handler block and check for updateResourceCounts call
$formHandlers = @(
    @{ name = "teacher-form";   pattern = "teacher-form.*?updateResourceCounts\(\)" },
    @{ name = "subject-form";   pattern = "subject-form.*?updateResourceCounts\(\)" },
    @{ name = "room-form";      pattern = "room-form.*?updateResourceCounts\(\)" },
    @{ name = "timeslot-form";  pattern = "timeslot-form.*?updateResourceCounts\(\)" },
    @{ name = "class-form";     pattern = "class-form.*?updateResourceCounts\(\)" }
)

foreach ($handler in $formHandlers) {
    if ($content -match "(?s)$($handler.pattern)") {
        Write-Host "PASS: updateResourceCounts() called in $($handler.name) handler"
    } else {
        Write-Host "FAIL: updateResourceCounts() NOT called in $($handler.name) handler"
        $passed = $false
    }
}

Write-Host ""

# --- Check 3: updateResourceCounts is called in loadExampleDataset and clearAllForms ---
$extraCallers = @("loadExampleDataset", "clearAllForms")
foreach ($caller in $extraCallers) {
    # Find the function body and check it contains updateResourceCounts
    if ($content -match "(?s)function $caller\(\).*?updateResourceCounts\(\)") {
        Write-Host "PASS: updateResourceCounts() called in $caller()"
    } else {
        Write-Host "FAIL: updateResourceCounts() NOT called in $caller()"
        $passed = $false
    }
}

Write-Host ""

if ($passed) {
    Write-Host "RESULT: PASS - Property 1 holds: all badge counts are driven by resourceData array lengths"
    exit 0
} else {
    Write-Host "RESULT: FAIL - Property 1 violated: one or more badge counts are not correctly wired"
    exit 1
}
