# Frontend Testing Checklist - Task 17

Quick checklist for testing the frontend. Check off items as you test them.

---

## Pre-Testing Setup

- [ ] Backend server is running (http://localhost:8080)
- [ ] Frontend files are accessible
- [ ] Browser is open (Chrome, Firefox, or Edge recommended)
- [ ] Test data reference is available (QUICK_TEST_DATA.md)

---

## 1. Forms and Resource Submission (15 min)

### Teacher Form
- [ ] Form displays correctly
- [ ] Can enter teacher name
- [ ] Can enter qualified subjects (comma-separated)
- [ ] Can enter max weekly load (number)
- [ ] Can enter availability (comma-separated slot IDs)
- [ ] Submit button works
- [ ] Success notification appears
- [ ] Form clears after submission

### Subject Form
- [ ] Form displays correctly
- [ ] Can enter subject name
- [ ] Can enter weekly hours
- [ ] Can select type (theory/lab)
- [ ] Can enter duration
- [ ] Submit button works
- [ ] Success notification appears

### Room Form
- [ ] Form displays correctly
- [ ] Can enter room name
- [ ] Can enter capacity
- [ ] Can select type (classroom/lab)
- [ ] Submit button works
- [ ] Success notification appears

### Time Slot Form
- [ ] Form displays correctly
- [ ] Can select day from dropdown
- [ ] Can enter period number
- [ ] Can select start time
- [ ] Can enter duration
- [ ] Submit button works
- [ ] Success notification appears

### Class Form
- [ ] Form displays correctly
- [ ] Can enter class name
- [ ] Can enter subject list (comma-separated)
- [ ] Submit button works
- [ ] Success notification appears

### Submit All Resources
- [ ] "Submit All Resources" button is visible
- [ ] Button submits data to backend
- [ ] Success notification appears
- [ ] Automatically switches to Generate section
- [ ] Error message if resources missing

### Clear Forms
- [ ] "Clear All Forms" button works
- [ ] All forms are reset
- [ ] Info notification appears

---

## 2. Timetable Generation (10 min)

### Generation Section
- [ ] Section displays after resource submission
- [ ] Hard constraints list is visible
- [ ] Soft constraints list is visible
- [ ] "Generate Timetable" button is prominent

### Generation Process
- [ ] Click "Generate Timetable" button
- [ ] Loading indicator appears
- [ ] Spinner animates
- [ ] Loading message displays
- [ ] Generation completes (10-30 seconds)
- [ ] Success message appears
- [ ] Automatically switches to Visualize section

### Error Handling
- [ ] Error message displays if generation fails
- [ ] Error is descriptive and helpful

---

## 3. Timetable Visualization (15 min)

### Grid Structure
- [ ] Timetable grid displays
- [ ] Corner cell shows "Room / Time"
- [ ] Time slot headers display (day, period, time)
- [ ] Room headers display in first column
- [ ] Grid is properly aligned

### Assignment Cells
- [ ] Assignment cells show class name (bold)
- [ ] Assignment cells show subject name
- [ ] Assignment cells show teacher name (small)
- [ ] Empty cells show "—"
- [ ] Cells have hover effect

### Color Coding
- [ ] Different subjects have different colors
- [ ] Colors are distinguishable
- [ ] Color coding is consistent

### Reliability Display
- [ ] Reliability score displays as percentage
- [ ] Progress bar shows correct width
- [ ] Bar color matches reliability level:
  - [ ] Green for high reliability (≥95%)
  - [ ] Yellow for medium (85-94%)
  - [ ] Orange for low (70-84%)
  - [ ] Red for critical (<70%)
- [ ] Risk level badge displays
- [ ] Risk level text is correct

---

## 4. Conflict Detection (5 min)

### Conflict Checking
- [ ] System checks for conflicts automatically
- [ ] Conflicts panel appears if conflicts exist
- [ ] Conflicts panel is hidden if no conflicts

### Conflict Highlighting
- [ ] Conflicting cells turn red
- [ ] Conflicting cells have pulsing animation
- [ ] Conflict text is white and readable
- [ ] Conflicts list shows all conflicts
- [ ] Conflict descriptions are clear

---

## 5. Explanation Modal (5 min)

### Opening Modal
- [ ] Click on an assignment cell
- [ ] Modal opens with fade-in animation
- [ ] Modal centers on screen
- [ ] Backdrop is semi-transparent

### Modal Content
- [ ] "Loading explanation..." appears initially
- [ ] Explanation text loads from API
- [ ] Explanation is readable and formatted
- [ ] Explanation describes the assignment

### Closing Modal
- [ ] Close button (×) works
- [ ] Close button has hover effect (rotation)
- [ ] OK button works
- [ ] Clicking outside modal closes it
- [ ] Modal fades out smoothly

---

## 6. Export Functionality (5 min)

### Export Buttons
- [ ] PDF export button is visible
- [ ] CSV export button is visible
- [ ] JSON export button is visible
- [ ] Buttons are disabled before generation
- [ ] Buttons are enabled after generation

### Export Operations
- [ ] Click "Export as PDF"
  - [ ] File downloads
  - [ ] Success notification appears
- [ ] Click "Export as CSV"
  - [ ] File downloads
  - [ ] Success notification appears
- [ ] Click "Export as JSON"
  - [ ] File downloads
  - [ ] Success notification appears

---

## 7. Responsive Design (10 min)

### Desktop View (>768px)
- [ ] Navigation buttons display horizontally
- [ ] Forms show in grid layout (multiple columns)
- [ ] Timetable grid is fully visible
- [ ] All text is readable
- [ ] No horizontal scrolling needed

### Tablet View (768px)
- [ ] Resize browser to 768px width
- [ ] Navigation buttons wrap appropriately
- [ ] Forms display in fewer columns
- [ ] Timetable grid is scrollable
- [ ] Generate section stacks vertically
- [ ] Modal is responsive

### Mobile View (<480px)
- [ ] Resize browser to 480px width
- [ ] Header title is readable
- [ ] Navigation buttons are compact
- [ ] Forms are single column
- [ ] Timetable grid has smaller cells
- [ ] Font sizes are reduced but readable
- [ ] Buttons stack vertically
- [ ] Modal takes up most of screen

---

## 8. Navigation (5 min)

### Section Switching
- [ ] Click "Resources" button
  - [ ] Resources section displays
  - [ ] Button becomes active (highlighted)
- [ ] Click "Generate" button
  - [ ] Generate section displays
  - [ ] Button becomes active
- [ ] Click "Visualize" button
  - [ ] Visualize section displays
  - [ ] Button becomes active
- [ ] Click "Analytics" button
  - [ ] Analytics section displays (placeholder)
  - [ ] Button becomes active

### Smooth Transitions
- [ ] Sections fade in smoothly
- [ ] No flickering or jumping
- [ ] Active button styling is clear

---

## 9. Notifications (5 min)

### Notification Types
- [ ] Success notifications are green
- [ ] Error notifications are red
- [ ] Info notifications are blue
- [ ] Warning notifications are orange (if any)

### Notification Behavior
- [ ] Notifications appear in top-right corner
- [ ] Notifications slide in from right
- [ ] Notifications have appropriate icons
- [ ] Notifications auto-dismiss after 3 seconds
- [ ] Multiple notifications stack properly

---

## 10. Overall User Experience (5 min)

### Visual Design
- [ ] Color scheme is consistent
- [ ] Layout is clean and organized
- [ ] Buttons are clearly labeled
- [ ] Forms are easy to understand
- [ ] Timetable is easy to read

### Performance
- [ ] Page loads quickly
- [ ] Interactions are responsive
- [ ] No lag when clicking buttons
- [ ] Animations are smooth
- [ ] No console errors (check browser console)

### Usability
- [ ] Workflow is intuitive
- [ ] Error messages are helpful
- [ ] Success feedback is clear
- [ ] Navigation is easy
- [ ] Overall experience is positive

---

## Issues Found

**Document any issues here:**

### Critical Issues (Blocking)
- None found / [List issues]

### Major Issues (Important but not blocking)
- None found / [List issues]

### Minor Issues (Nice to fix)
- None found / [List issues]

### Suggestions for Improvement
- [List suggestions]

---

## Test Summary

**Date Tested**: _______________  
**Browser Used**: _______________  
**Screen Resolution**: _______________

**Total Items**: 150+  
**Items Passed**: _____  
**Items Failed**: _____  
**Items Skipped**: _____

**Overall Status**: ☐ Pass  ☐ Pass with Minor Issues  ☐ Fail

---

## Sign-Off

**Tester Name**: _______________  
**Date**: _______________  
**Signature**: _______________

**Ready to proceed to Phase 5?**: ☐ Yes  ☐ No (fix issues first)

---

## Next Steps

If all tests pass:
1. ✅ Mark Task 17 as complete
2. ✅ Update tasks.md status
3. ✅ Proceed to Phase 5: Advanced Features Implementation

If issues found:
1. ⚠️ Document issues in detail
2. ⚠️ Prioritize fixes
3. ⚠️ Fix critical issues
4. ⚠️ Re-test affected areas
