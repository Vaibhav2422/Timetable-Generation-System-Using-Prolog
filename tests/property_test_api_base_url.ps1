# Property Test: All fetch calls use API_BASE_URL
# Feature: frontend-bug-fixes, Property 3: All fetch calls use API_BASE_URL
# Validates: Requirements 3.2

$scriptPath = "frontend/script.js"

Write-Host "Running Property 3: All fetch calls use API_BASE_URL"
Write-Host "File: $scriptPath"
Write-Host ""

# Check for any API_BASE reference that is NOT API_BASE_URL
$matches = Select-String -Path $scriptPath -Pattern "API_BASE[^_U]" -AllMatches

if ($matches) {
    Write-Host "FAIL: Found stray API_BASE references (not API_BASE_URL):"
    foreach ($m in $matches) {
        Write-Host "  Line $($m.LineNumber): $($m.Line.Trim())"
    }
    exit 1
} else {
    Write-Host "PASS: No stray API_BASE references found. All fetch calls use API_BASE_URL."
    exit 0
}
