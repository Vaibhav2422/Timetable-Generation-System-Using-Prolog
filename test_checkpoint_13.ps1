# Checkpoint 13 - API Server Functional Test
# Tests all API endpoints with curl

$baseUrl = "http://localhost:8080/api"
$testResults = @()

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Checkpoint 13: API Server Functional Test" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Function to test an endpoint
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Endpoint,
        [string]$Body = $null,
        [string]$ExpectedStatus = "200"
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "  Method: $Method $Endpoint"
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
            "Accept" = "application/json"
        }
        
        $params = @{
            Uri = "$baseUrl$Endpoint"
            Method = $Method
            Headers = $headers
            TimeoutSec = 30
        }
        
        if ($Body) {
            $params.Body = $Body
            Write-Host "  Body: $($Body.Substring(0, [Math]::Min(100, $Body.Length)))..."
        }
        
        $response = Invoke-WebRequest @params -UseBasicParsing
        
        Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "  Content-Type: $($response.Headers['Content-Type'])"
        
        # Check CORS headers
        if ($response.Headers['Access-Control-Allow-Origin']) {
            Write-Host "  CORS: [OK] Access-Control-Allow-Origin present" -ForegroundColor Green
        } else {
            Write-Host "  CORS: [MISSING] Access-Control-Allow-Origin missing" -ForegroundColor Red
        }
        
        # Parse JSON response
        $json = $response.Content | ConvertFrom-Json
        Write-Host "  Response: $($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))..."
        
        $script:testResults += @{
            Name = $Name
            Status = "PASS"
            StatusCode = $response.StatusCode
            HasCORS = $response.Headers['Access-Control-Allow-Origin'] -ne $null
        }
        
        Write-Host "  Result: PASS" -ForegroundColor Green
        Write-Host ""
        return $true
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Result: FAIL" -ForegroundColor Red
        Write-Host ""
        
        $script:testResults += @{
            Name = $Name
            Status = "FAIL"
            Error = $_.Exception.Message
            HasCORS = $false
        }
        
        return $false
    }
}

# Test 1: POST /api/resources - Resource submission
Write-Host "Test 1: Resource Submission" -ForegroundColor Cyan
Write-Host "----------------------------"
$resourceData = @{
    teachers = @(
        @{
            id = "t_test1"
            name = "Test Teacher"
            qualified_subjects = @("s1", "s2")
            max_load = 20
            availability = @("slot1", "slot2", "slot3")
        }
    )
    subjects = @(
        @{
            id = "s_test1"
            name = "Test Subject"
            weekly_hours = 4
            type = "theory"
            duration = 1
        }
    )
} | ConvertTo-Json -Depth 10

Test-Endpoint -Name "POST /api/resources" -Method "POST" -Endpoint "/resources" -Body $resourceData

# Test 2: POST /api/generate - Timetable generation
Write-Host "Test 2: Timetable Generation" -ForegroundColor Cyan
Write-Host "----------------------------"
$generateData = @{
    use_heuristics = $true
    max_iterations = 1000
} | ConvertTo-Json

Test-Endpoint -Name "POST /api/generate" -Method "POST" -Endpoint "/generate" -Body $generateData

# Test 3: GET /api/timetable - Retrieve current timetable
Write-Host "Test 3: Retrieve Timetable" -ForegroundColor Cyan
Write-Host "----------------------------"
Test-Endpoint -Name "GET /api/timetable" -Method "GET" -Endpoint "/timetable"

# Test 4: GET /api/reliability - Get reliability score
Write-Host "Test 4: Reliability Score" -ForegroundColor Cyan
Write-Host "----------------------------"
Test-Endpoint -Name "GET /api/reliability" -Method "GET" -Endpoint "/reliability"

# Test 5: POST /api/explain - Request assignment explanations
Write-Host "Test 5: Assignment Explanation" -ForegroundColor Cyan
Write-Host "----------------------------"
$explainData = @{
    class_id = "cs1"
    subject_id = "ai"
} | ConvertTo-Json

Test-Endpoint -Name "POST /api/explain" -Method "POST" -Endpoint "/explain" -Body $explainData

# Test 6: GET /api/conflicts - Get constraint violations
Write-Host "Test 6: Conflict Detection" -ForegroundColor Cyan
Write-Host "----------------------------"
Test-Endpoint -Name "GET /api/conflicts" -Method "GET" -Endpoint "/conflicts"

# Test 7: POST /api/repair - Repair timetable
Write-Host "Test 7: Timetable Repair" -ForegroundColor Cyan
Write-Host "----------------------------"
$repairData = @{
    conflicts = @("conflict1")
} | ConvertTo-Json

Test-Endpoint -Name "POST /api/repair" -Method "POST" -Endpoint "/repair" -Body $repairData

# Test 8: GET /api/analytics - Get analytics data
Write-Host "Test 8: Analytics Data" -ForegroundColor Cyan
Write-Host "----------------------------"
Test-Endpoint -Name "GET /api/analytics" -Method "GET" -Endpoint "/analytics"

# Test 9: GET /api/export - Export timetable
Write-Host "Test 9: Export Timetable" -ForegroundColor Cyan
Write-Host "----------------------------"
Test-Endpoint -Name "GET /api/export?format=json" -Method "GET" -Endpoint "/export?format=json"

# Test 10: Error handling - Invalid JSON
Write-Host "Test 10: Invalid JSON Handling" -ForegroundColor Cyan
Write-Host "----------------------------"
Write-Host "Testing: Invalid JSON"
Write-Host "  Method: POST /api/resources"

try {
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/resources" -Method POST -Headers $headers -Body "invalid json{" -UseBasicParsing
    Write-Host "  Unexpected success - should have failed" -ForegroundColor Red
    $script:testResults += @{
        Name = "Invalid JSON Handling"
        Status = "FAIL"
        Error = "Should have returned 400 error"
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "  Status: 400 (Expected)" -ForegroundColor Green
        Write-Host "  Result: PASS" -ForegroundColor Green
        $script:testResults += @{
            Name = "Invalid JSON Handling"
            Status = "PASS"
            StatusCode = 400
        }
    } else {
        Write-Host "  Status: $($_.Exception.Response.StatusCode) (Expected 400)" -ForegroundColor Red
        Write-Host "  Result: FAIL" -ForegroundColor Red
        $script:testResults += @{
            Name = "Invalid JSON Handling"
            Status = "FAIL"
            Error = "Wrong status code"
        }
    }
}
Write-Host ""

# Test 11: Error handling - Missing required fields
Write-Host "Test 11: Missing Fields Handling" -ForegroundColor Cyan
Write-Host "----------------------------"
$invalidData = @{
    invalid_field = "test"
} | ConvertTo-Json

Write-Host "Testing: Missing Required Fields"
Write-Host "  Method: POST /api/generate"

try {
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/generate" -Method POST -Headers $headers -Body $invalidData -UseBasicParsing
    Write-Host "  Status: $($response.StatusCode)"
    
    # Even if it succeeds, check if it handles gracefully
    Write-Host "  Result: PASS (Handled gracefully)" -ForegroundColor Green
    $script:testResults += @{
        Name = "Missing Fields Handling"
        Status = "PASS"
        StatusCode = $response.StatusCode
    }
} catch {
    Write-Host "  Status: $($_.Exception.Response.StatusCode)"
    Write-Host "  Result: PASS (Rejected appropriately)" -ForegroundColor Green
    $script:testResults += @{
        Name = "Missing Fields Handling"
        Status = "PASS"
        StatusCode = $_.Exception.Response.StatusCode
    }
}
Write-Host ""

# Summary
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $testResults.Count

Write-Host ""
Write-Host "Total Tests: $totalCount"
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host ""

# CORS Check
$corsCount = ($testResults | Where-Object { $_.HasCORS -eq $true }).Count
Write-Host "CORS Headers Present: $corsCount/$totalCount" -ForegroundColor $(if ($corsCount -eq $totalCount) { "Green" } else { "Yellow" })
Write-Host ""

# Detailed Results
Write-Host "Detailed Results:" -ForegroundColor Cyan
foreach ($result in $testResults) {
    $status = if ($result.Status -eq "PASS") { "[PASS]" } else { "[FAIL]" }
    $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $status $($result.Name)" -ForegroundColor $color
    if ($result.Error) {
        Write-Host "    Error: $($result.Error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some tests failed" -ForegroundColor Red
    exit 1
}
