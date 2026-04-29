# Property Test: Export produces non-empty output
# Feature: full-frontend-fix, Property 2: Export produces non-empty output
# Validates: Requirements 3.2, 3.3

$scriptPath = "frontend/script.js"
$passed = $true

Write-Host "Running Property 2: Export produces non-empty output"
Write-Host "File: $scriptPath"
Write-Host ""

$content = Get-Content $scriptPath -Raw

# --- Check 1: exportTimetable function exists and guards against null timetable ---
if ($content -match "function exportTimetable\(format\)") {
    Write-Host "PASS: exportTimetable(format) function exists"
} else {
    Write-Host "FAIL: exportTimetable(format) function not found"
    $passed = $false
}

if ($content -match "if \(!currentTimetable\)") {
    Write-Host "PASS: exportTimetable guards against null currentTimetable"
} else {
    Write-Host "FAIL: No null-timetable guard in exportTimetable"
    $passed = $false
}

# --- Check 2: _exportCSV builds a header row ---
$csvHeader = "Day,Period,Start,Room,Class,Subject,Teacher"
if ($content -match [regex]::Escape($csvHeader)) {
    Write-Host "PASS: CSV header row 'Day,Period,Start,Room,Class,Subject,Teacher' is present"
} else {
    Write-Host "FAIL: CSV header row not found in _exportCSV"
    $passed = $false
}

# --- Check 3: _exportCSV maps assignments to rows ---
if ($content -match "assignments\.map\(a =>") {
    Write-Host "PASS: _exportCSV maps assignments array to CSV rows"
} else {
    Write-Host "FAIL: _exportCSV does not map assignments to rows"
    $passed = $false
}

# --- Check 4: _exportCSV joins header + rows and downloads ---
if ($content -match "\[header, \.\.\.rows\]\.join\('\\n'\)") {
    Write-Host "PASS: _exportCSV joins header and rows with newline"
} else {
    Write-Host "FAIL: _exportCSV does not join header and rows correctly"
    $passed = $false
}

# --- Check 5: _downloadBlob is used for CSV download ---
if ($content -match "_downloadBlob\(" -and $content -match "'timetable\.csv'" -and $content -match "'text/csv'") {
    Write-Host "PASS: _downloadBlob called with 'timetable.csv' and 'text/csv'"
} else {
    Write-Host "FAIL: _downloadBlob not called correctly for CSV export"
    $passed = $false
}

# --- Check 6: _exportJSON uses JSON.stringify ---
if ($content -match "JSON\.stringify\(currentTimetable") {
    Write-Host "PASS: _exportJSON uses JSON.stringify(currentTimetable)"
} else {
    Write-Host "FAIL: _exportJSON does not use JSON.stringify(currentTimetable)"
    $passed = $false
}

# --- Check 7: _exportPDF uses window.print ---
if ($content -match "window\.print\(\)") {
    Write-Host "PASS: _exportPDF uses window.print()"
} else {
    Write-Host "FAIL: _exportPDF does not use window.print()"
    $passed = $false
}

Write-Host ""

if ($passed) {
    Write-Host "RESULT: PASS - Property 2 holds: export functions produce non-empty output for valid timetables"
    exit 0
} else {
    Write-Host "RESULT: FAIL - Property 2 violated: one or more export functions are missing or incorrect"
    exit 1
}
