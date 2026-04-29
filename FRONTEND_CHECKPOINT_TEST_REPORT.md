# Frontend Checkpoint Test Report
## Task 17: Frontend Functional Testing

**Date**: 2026-03-13  
**Status**: In Progress  
**Backend Server**: Running on http://localhost:8080

---

## Test Environment

- **Backend API Server**: ✅ Running (SWI-Prolog)
- **Frontend Files**: ✅ Present (index.html, style.css, script.js)
- **Browser Access**: http://localhost:8080 (via file:// or local server)

---

## Test Plan

### 1. Forms and Resource Submission Testing

#### 1.1 Teacher Form
- [ ] Form displays correctly with all required fields
- [ ] Name field accepts valid input (letters, spaces, periods)
- [ ] Qualified subjects field accepts comma-separated values
- [ ] Max weekly load accepts numbers (1-40)
- [ ] Availability field accepts comma-separated slot IDs
- [ ] Form validation works (required fields, patterns)
- [ ] Submit button adds teacher to local state
- [ ] Success notification appears after submission

#### 1.2 Subject Form
- [ ] Form displays correctly with all required fields
- [ ] Name field accepts valid input
- [ ] Weekly hours accepts numbers (1-20)
- [ ] Type dropdown has theory/lab options
- [ ] Duration accepts decimal values (1-4)
- [ ] Form validation works
- [ ] Submit button adds subject to local state
- [ ] Success notification appears

#### 1.3 Room Form
- [ ] Form displays correctly
- [ ] Name field accepts alphanumeric input
- [ ] Capacity accepts numbers (10-200)
- [ ] Type dropdown has classroom/lab options
- [ ] Form validation works
- [ ] Submit button adds room to local state
- [ ] Success notification appears

#### 1.4 Time Slot Form
- [ ] Form displays correctly
- [ ] Day dropdown has all weekdays
- [ ] Period accepts numbers (1-10)
- [ ] Start time picker works
- [ ] Duration accepts decimal values
- [ ] Form validation works
- [ ] Submit button adds timeslot to local state
- [ ] Success notification appears

#### 1.5 Class Form
- [ ] Form displays correctly
- [ ] Name field accepts valid input
- [ ] Subject list accepts comma-separated values
- [ ] Form validation works
- [ ] Submit button adds class to local state
- [ ] Success notification appears

#### 1.6 Submit All Resources
- [ ] Button is visible and clickable
- [ ] Validates that all resource types have at least one entry
- [ ] Sends POST request to /api/resources
- [ ] Handles successful response
- [ ] Handles error response with descriptive message
- [ ] Shows success notification
- [ ] Automatically switches to Generate section

#### 1.7 Clear All Forms
- [ ] Button clears all form inputs
- [ ] Resets local resource state
- [ ] Shows info notification

---

### 2. Timetable Generation and Visualization Testing

#### 2.1 Generation Section
- [ ] Section displays correctly
- [ ] Hard constraints list is visible
- [ ] Soft constraints list is visible
- [ ] Generate button is prominent and clickable
- [ ] Loading indicator appears during generation
- [ ] Loading spinner animates correctly
- [ ] Result box shows success/error message
- [ ] Automatically switches to Visualize section on success

#### 2.2 Generation API Call
- [ ] Sends POST request to /api/generate
- [ ] Handles successful response with timetable data
- [ ] Handles error response gracefully
- [ ] Stores timetable in currentTimetable variable
- [ ] Stores reliability in currentReliability variable
- [ ] Shows appropriate notifications

#### 2.3 Timetable Grid Rendering
- [ ] Grid displays with correct structure
- [ ] Corner cell shows "Room / Time"
- [ ] Time slot headers display correctly (day, period, time)
- [ ] Room headers display in first column
- [ ] Assignment cells show class, subject, teacher
- [ ] Empty cells show "—" symbol
- [ ] Grid is responsive and scrollable
- [ ] Color coding applies based on subject type
- [ ] Grid layout adapts to number of rooms and slots

#### 2.4 Reliability Display
- [ ] Reliability score displays as percentage
- [ ] Progress bar fills to correct width
- [ ] Bar color changes based on reliability level:
  - Green for ≥95% (Low risk)
  - Yellow for 85-94% (Medium risk)
  - Orange for 70-84% (High risk)
  - Red for <70% (Critical risk)
- [ ] Risk badge shows correct category
- [ ] Risk badge has appropriate color

---

### 3. Conflict Detection and Highlighting Testing

#### 3.1 Conflict Detection
- [ ] Sends GET request to /api/conflicts
- [ ] Parses conflict response correctly
- [ ] Identifies teacher conflicts
- [ ] Identifies room conflicts
- [ ] Identifies other constraint violations

#### 3.2 Conflict Highlighting
- [ ] Conflicting cells turn red
- [ ] Conflicting cells have pulsing animation
- [ ] Conflict border is visible (3px solid)
- [ ] Text in conflicting cells is white
- [ ] Conflicts panel appears when conflicts exist
- [ ] Conflicts list shows all detected conflicts
- [ ] Conflict descriptions are readable

#### 3.3 Conflicts Panel
- [ ] Panel displays when conflicts are detected
- [ ] Panel is hidden when no conflicts exist
- [ ] Panel has red accent color
- [ ] Conflict list items are formatted correctly
- [ ] Each conflict has descriptive text

---

### 4. Explanation Modal Testing

#### 4.1 Modal Trigger
- [ ] Clicking on assignment cell opens modal
- [ ] Modal appears with fade-in animation
- [ ] Modal centers on screen
- [ ] Modal has semi-transparent backdrop

#### 4.2 Modal Content
- [ ] Shows "Loading explanation..." initially
- [ ] Sends POST request to /api/explain
- [ ] Displays explanation text from API
- [ ] Handles API errors gracefully
- [ ] Shows error message if explanation fails
- [ ] Explanation is readable and formatted

#### 4.3 Modal Interaction
- [ ] Close button (×) works
- [ ] OK button closes modal
- [ ] Clicking outside modal closes it
- [ ] Close button has hover effect (rotation)
- [ ] Modal slides up on open
- [ ] Modal fades out on close

---

### 5. Export Functionality Testing

#### 5.1 Export Buttons
- [ ] PDF export button is visible
- [ ] CSV export button is visible
- [ ] JSON export button is visible
- [ ] Buttons are disabled before timetable generation
- [ ] Buttons are enabled after successful generation
- [ ] Buttons have appropriate icons

#### 5.2 Export Operations
- [ ] PDF export sends GET request to /api/export?format=pdf
- [ ] CSV export sends GET request to /api/export?format=csv
- [ ] JSON export sends GET request to /api/export?format=json
- [ ] File download triggers automatically
- [ ] Downloaded file has correct filename
- [ ] Downloaded file has correct format
- [ ] Success notification appears after export
- [ ] Error notification appears if export fails

---

### 6. Responsive Design Testing

#### 6.1 Desktop View (>768px)
- [ ] Navigation buttons display horizontally
- [ ] Forms grid shows multiple columns
- [ ] Timetable grid is fully visible
- [ ] All sections fit within viewport
- [ ] No horizontal scrolling required
- [ ] Font sizes are readable

#### 6.2 Tablet View (768px)
- [ ] Navigation buttons wrap appropriately
- [ ] Forms display in single column
- [ ] Timetable grid is scrollable
- [ ] Generate section stacks vertically
- [ ] Modal is responsive
- [ ] Notifications fit on screen

#### 6.3 Mobile View (<480px)
- [ ] Header title is readable
- [ ] Navigation buttons are compact
- [ ] Forms are single column
- [ ] Timetable grid has smaller cells
- [ ] Font sizes are reduced but readable
- [ ] Buttons stack vertically
- [ ] Modal takes up most of screen
- [ ] Notifications are narrower

---

## Test Execution Instructions

### Manual Testing Steps

1. **Open Frontend**
   - Navigate to `frontend/index.html` in a web browser
   - Or serve via local HTTP server

2. **Test Resource Forms**
   - Fill out each form with valid data
   - Test form validation with invalid data
   - Submit individual forms
   - Verify notifications appear
   - Click "Submit All Resources"
   - Verify API call succeeds

3. **Test Generation**
   - Click "Generate Timetable" button
   - Observe loading indicator
   - Wait for generation to complete
   - Verify automatic navigation to Visualize section

4. **Test Visualization**
   - Verify timetable grid renders correctly
   - Check reliability display
   - Look for any conflicts
   - Click on assignment cells
   - Verify explanation modal works

5. **Test Export**
   - Click each export button
   - Verify file downloads
   - Check file contents

6. **Test Responsive Design**
   - Resize browser window
   - Test at different breakpoints
   - Verify layout adapts correctly

---

## Known Issues and Notes

- Export functionality requires backend implementation of /api/export endpoint
- Analytics section is placeholder (Phase 5 feature)
- Some advanced features are not yet implemented (Phase 5)

---

## Test Results

*To be filled during testing*

### Summary
- **Total Tests**: TBD
- **Passed**: TBD
- **Failed**: TBD
- **Blocked**: TBD

### Critical Issues
*None identified yet*

### Recommendations
*To be added after testing*

---

## Next Steps

1. Execute manual tests following the test plan
2. Document any issues found
3. Fix critical bugs before proceeding to Phase 5
4. Mark task 17 as complete once all tests pass
