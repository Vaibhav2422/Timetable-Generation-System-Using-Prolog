# Quick Test Data for Frontend Testing

Use this data to quickly fill out the forms for testing.

---

## Teacher Form Test Data

### Teacher 1
- **Name**: Dr. Alice Johnson
- **Qualified Subjects**: math,physics
- **Max Weekly Load**: 20
- **Availability**: slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10

### Teacher 2
- **Name**: Prof. Bob Smith
- **Qualified Subjects**: chemistry,biology
- **Max Weekly Load**: 18
- **Availability**: slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10

### Teacher 3
- **Name**: Dr. Carol Williams
- **Qualified Subjects**: english,history
- **Max Weekly Load**: 20
- **Availability**: slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10

---

## Subject Form Test Data

### Subject 1
- **Name**: Mathematics
- **Weekly Hours**: 4
- **Type**: theory
- **Duration**: 1

### Subject 2
- **Name**: Physics
- **Weekly Hours**: 3
- **Type**: theory
- **Duration**: 1

### Subject 3
- **Name**: Chemistry
- **Weekly Hours**: 3
- **Type**: theory
- **Duration**: 1

### Subject 4
- **Name**: Chemistry Lab
- **Weekly Hours**: 2
- **Type**: lab
- **Duration**: 2

### Subject 5
- **Name**: Biology
- **Weekly Hours**: 3
- **Type**: theory
- **Duration**: 1

---

## Room Form Test Data

### Room 1
- **Name**: Room 101
- **Capacity**: 30
- **Type**: classroom

### Room 2
- **Name**: Room 102
- **Capacity**: 35
- **Type**: classroom

### Room 3
- **Name**: Lab A
- **Capacity**: 25
- **Type**: lab

### Room 4
- **Name**: Lab B
- **Capacity**: 25
- **Type**: lab

---

## Time Slot Form Test Data

### Slot 1
- **Day**: monday
- **Period**: 1
- **Start Time**: 09:00
- **Duration**: 1

### Slot 2
- **Day**: monday
- **Period**: 2
- **Start Time**: 10:00
- **Duration**: 1

### Slot 3
- **Day**: monday
- **Period**: 3
- **Start Time**: 11:00
- **Duration**: 1

### Slot 4
- **Day**: tuesday
- **Period**: 1
- **Start Time**: 09:00
- **Duration**: 1

### Slot 5
- **Day**: tuesday
- **Period**: 2
- **Start Time**: 10:00
- **Duration**: 1

### Slot 6
- **Day**: wednesday
- **Period**: 1
- **Start Time**: 09:00
- **Duration**: 1

### Slot 7
- **Day**: wednesday
- **Period**: 2
- **Start Time**: 10:00
- **Duration**: 1

### Slot 8
- **Day**: thursday
- **Period**: 1
- **Start Time**: 09:00
- **Duration**: 1

### Slot 9
- **Day**: thursday
- **Period**: 2
- **Start Time**: 10:00
- **Duration**: 1

### Slot 10
- **Day**: friday
- **Period**: 1
- **Start Time**: 09:00
- **Duration**: 1

---

## Class Form Test Data

### Class 1
- **Name**: CS-101
- **Subject List**: math,physics,chemistry

### Class 2
- **Name**: CS-102
- **Subject List**: math,biology,english

### Class 3
- **Name**: CS-103
- **Subject List**: physics,chemistry,history

---

## Quick Copy-Paste Values

**For quick testing, copy these comma-separated values:**

### Teachers (Qualified Subjects)
```
math,physics
chemistry,biology
english,history
```

### Teachers (Availability)
```
slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10
```

### Classes (Subject List)
```
math,physics,chemistry
math,biology,english
physics,chemistry,history
```

---

## Testing Workflow

1. **Add Resources** (5-10 minutes)
   - Add at least 3 teachers
   - Add at least 5 subjects (including 1 lab)
   - Add at least 4 rooms (including 1 lab)
   - Add at least 10 time slots
   - Add at least 3 classes

2. **Submit Resources**
   - Click "Submit All Resources" button
   - Verify success notification appears
   - Verify automatic navigation to Generate section

3. **Generate Timetable**
   - Click "Generate Timetable" button
   - Observe loading indicator
   - Wait for generation to complete (may take 10-30 seconds)
   - Verify success message
   - Verify automatic navigation to Visualize section

4. **Test Visualization**
   - Check timetable grid displays correctly
   - Verify reliability score is shown
   - Check risk level badge
   - Click on assignment cells to see explanations
   - Look for any conflicts (red cells)

5. **Test Export**
   - Click "Export as PDF" button
   - Click "Export as CSV" button
   - Click "Export as JSON" button
   - Verify files download

6. **Test Responsive Design**
   - Resize browser window to different widths
   - Test at 1920px (desktop)
   - Test at 768px (tablet)
   - Test at 480px (mobile)
   - Verify layout adapts appropriately

---

## Expected Results

### After Resource Submission
- ✅ Success notification: "All resources submitted successfully!"
- ✅ Automatic switch to Generate section
- ✅ Generate button is enabled

### After Timetable Generation
- ✅ Loading indicator appears
- ✅ Success message: "Timetable generated successfully!"
- ✅ Automatic switch to Visualize section
- ✅ Timetable grid populated with assignments
- ✅ Reliability score displayed (typically 85-99%)
- ✅ Risk level badge shows (Low/Medium/High)
- ✅ Export buttons are enabled

### Timetable Grid
- ✅ Headers show days and time slots
- ✅ Room names in first column
- ✅ Assignment cells show:
  - Class name (bold)
  - Subject name
  - Teacher name (small text)
- ✅ Color coding by subject type
- ✅ Empty cells show "—"

### Clicking Assignment Cell
- ✅ Modal opens with fade-in animation
- ✅ Explanation text displays
- ✅ Close button (×) works
- ✅ OK button works
- ✅ Clicking outside modal closes it

---

## Troubleshooting

### Issue: "Failed to submit resources"
- **Solution**: Check that backend server is running on http://localhost:8080
- **Check**: Open http://localhost:8080 in browser to verify server is accessible

### Issue: "Failed to generate timetable"
- **Solution**: Ensure all resource types have at least one entry
- **Check**: Verify you added teachers, subjects, rooms, timeslots, and classes

### Issue: CORS errors in browser console
- **Solution**: Use a local HTTP server instead of opening HTML file directly
- **Run**: `python -m http.server 3000` in project directory
- **Open**: http://localhost:3000/frontend/index.html

### Issue: Timetable generation takes too long
- **Expected**: Generation may take 10-30 seconds for complex schedules
- **If >60 seconds**: Check backend logs for errors
- **Solution**: Reduce number of classes or subjects for testing

### Issue: Export buttons don't work
- **Check**: Verify timetable was generated successfully
- **Check**: Backend /api/export endpoint is implemented
- **Note**: Export functionality requires full backend implementation

---

## Browser Compatibility

**Tested and Recommended:**
- ✅ Google Chrome (latest)
- ✅ Mozilla Firefox (latest)
- ✅ Microsoft Edge (latest)

**May Have Issues:**
- ⚠️ Internet Explorer (not supported)
- ⚠️ Safari (may have minor CSS differences)

---

## Performance Notes

- **Resource Submission**: < 1 second
- **Timetable Generation**: 10-30 seconds (depends on complexity)
- **Grid Rendering**: < 1 second
- **Modal Opening**: Instant
- **Export**: 1-3 seconds per file

---

## Next Steps After Testing

1. Document any issues found in FRONTEND_CHECKPOINT_TEST_REPORT.md
2. Take screenshots of successful tests
3. Report any bugs or unexpected behavior
4. If all tests pass, mark Task 17 as complete
5. Proceed to Phase 5: Advanced Features Implementation
