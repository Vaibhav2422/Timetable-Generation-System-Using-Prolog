// ============================================
// AI-Based Timetable Generation System
// Frontend JavaScript Logic
// ============================================

// ============================================
// Configuration and State Management
// ============================================

// API base URL - use relative path so it works from any origin
const API_BASE_URL = 'http://localhost:8081/api';

// Global error handler to catch silent failures
window.addEventListener('error', (e) => {
    console.error('Global JS error:', e.message, e.filename, e.lineno);
});
window.addEventListener('unhandledrejection', (e) => {
    console.error('Unhandled promise rejection:', e.reason);
});

// Global state
let currentTimetable = null;
let currentReliability = null;
let _resourcesSubmittedToBackend = false;
let resourceData = {
    teachers: [],
    subjects: [],
    rooms: [],
    timeslots: [],
    classes: []
};

// ============================================
// Initialization
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    initializeNavigation();
    initializeResourceForms();
    initializeGenerateSection();
    initializeVisualizationSection();
    initializeModal();
    initializeConflictSuggestions();
    initializeScenarios();
    initializeRecommendations();
    initializeHeatmap();
    initializeMultiSolutions();
    initializeConstraintSliders();
    initializeRealtimeValidation();
    initializeGA();
    initializeDragEdit();
    initializeConflictPrediction();
    initializeVersioning();
    initializeNLQuery();
});

// ============================================
// Navigation and Section Switching
// ============================================

function initializeNavigation() {
    const navButtons = document.querySelectorAll('.nav-btn');
    
    navButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetSection = button.getAttribute('data-section');
            switchSection(targetSection);
            
            // Update active button
            navButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
        });
    });
}

function switchSection(sectionName) {
    // Hide all sections
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));

    const targetSection = document.getElementById(`${sectionName}-section`);
    if (targetSection) {
        targetSection.classList.add('active');
    }

    // Sections that need a generated timetable
    const requiresTimetable = [
        'visualize','analytics','recommendations','heatmap','search-stats',
        'multi-solutions','constraints','ga','drag-edit','learning',
        'pattern-discovery','whatif-dashboard','constraint-graph','complexity',
        'nl-query','versions'
    ];

    if (requiresTimetable.includes(sectionName) && !currentTimetable) {
        _injectNoTimetableBanner(targetSection, sectionName);
        return; // don't auto-load if no timetable
    }

    // Remove any existing banner when timetable exists
    if (targetSection) {
        const existing = targetSection.querySelector('.no-timetable-banner');
        if (existing) existing.remove();
    }

    // Auto-load map
    const autoLoad = {
        'analytics':        loadAnalytics,
        'recommendations':  loadRecommendations,
        'heatmap':          () => loadHeatmap(typeof currentHeatmapType !== 'undefined' ? currentHeatmapType : 'teacher'),
        'search-stats':     loadSearchStatistics,
        'learning':         loadLearningStats,
        'constraint-graph': loadConstraintGraph,
        'complexity':       loadComplexityAnalysis,
        'versions':         loadVersionList,
        'scenarios':        _populateScenarioDropdowns,
        'drag-edit':        loadTimetableForEditing,
    };

    if (autoLoad[sectionName]) {
        try { autoLoad[sectionName](); } catch(e) { console.warn('Auto-load failed for', sectionName, e); }
    }
}

function _injectNoTimetableBanner(section, sectionName) {
    if (!section) return;
    // Remove existing banner first
    const existing = section.querySelector('.no-timetable-banner');
    if (existing) return; // already shown

    const banner = document.createElement('div');
    banner.className = 'no-timetable-banner';
    banner.innerHTML = `
        <span class="no-timetable-icon">⚠</span>
        <span>No timetable generated yet. Generate one first to use this section.</span>
        <button class="btn btn-primary btn-sm" onclick="
            switchSection('generate');
            document.querySelectorAll('.nav-btn').forEach(b =>
                b.classList.toggle('active', b.getAttribute('data-section') === 'generate'));
        ">Go to Generate →</button>`;
    section.insertBefore(banner, section.firstChild);
}

// ============================================
// Resource Form Handling
// ============================================

function updateResourceCounts() {
    document.getElementById('count-teachers').textContent = resourceData.teachers.length;
    document.getElementById('count-subjects').textContent = resourceData.subjects.length;
    document.getElementById('count-rooms').textContent = resourceData.rooms.length;
    document.getElementById('count-timeslots').textContent = resourceData.timeslots.length;
    document.getElementById('count-classes').textContent = resourceData.classes.length;

    // Update badge colors
    ['teachers','subjects','rooms','timeslots','classes'].forEach(type => {
        const badge = document.getElementById(`count-${type}`);
        badge.style.background = resourceData[type].length > 0 ? '#27ae60' : '#e74c3c';
    });

    // Show preview list
    const preview = document.getElementById('resource-list-preview');
    let html = '';
    if (resourceData.teachers.length) html += `<p><strong>Teachers:</strong> ${resourceData.teachers.map(t=>t.name).join(', ')}</p>`;
    if (resourceData.subjects.length) html += `<p><strong>Subjects:</strong> ${resourceData.subjects.map(s=>s.name).join(', ')}</p>`;
    if (resourceData.rooms.length) html += `<p><strong>Rooms:</strong> ${resourceData.rooms.map(r=>r.name).join(', ')}</p>`;
    if (resourceData.classes.length) html += `<p><strong>Classes:</strong> ${resourceData.classes.map(c=>c.name).join(', ')}</p>`;
    if (resourceData.timeslots.length) html += `<p><strong>Time Slots:</strong> ${resourceData.timeslots.length} slots added</p>`;
    preview.innerHTML = html;

    // Keep generate-section mini panel in sync
    if (typeof updateGenResourceCounts === 'function') updateGenResourceCounts();
}

function initializeResourceForms() {
    const safe = (id, fn) => { const el = document.getElementById(id); if (el) fn(el); };

    safe('teacher-form', el => el.addEventListener('submit', (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const teacher = {
            id: `teacher_${Date.now()}`,
            name: formData.get('name'),
            subjects: formData.get('subjects').split(',').map(s => s.trim()),
            maxload: parseInt(formData.get('maxload')),
            availability: formData.get('availability').split(',').map(s => s.trim())
        };
        resourceData.teachers.push(teacher);
        showNotification('success', `Teacher ${teacher.name} added successfully`);
        e.target.reset();
        updateResourceCounts();
    }));

    safe('subject-form', el => el.addEventListener('submit', (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const subject = {
            id: `subject_${Date.now()}`,
            name: formData.get('name'),
            hours: parseInt(formData.get('hours')),
            type: formData.get('type'),
            duration: parseFloat(formData.get('duration'))
        };
        resourceData.subjects.push(subject);
        showNotification('success', `Subject ${subject.name} added successfully`);
        e.target.reset();
        updateResourceCounts();
    }));

    safe('room-form', el => el.addEventListener('submit', (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const room = {
            id: `room_${Date.now()}`,
            name: formData.get('name'),
            capacity: parseInt(formData.get('capacity')),
            type: formData.get('type')
        };
        resourceData.rooms.push(room);
        showNotification('success', `Room ${room.name} added successfully`);
        e.target.reset();
        updateResourceCounts();
    }));

    safe('timeslot-form', el => el.addEventListener('submit', (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const timeslot = {
            id: `slot_${Date.now()}`,
            day: formData.get('day'),
            period: parseInt(formData.get('period')),
            start: formData.get('start'),
            duration: parseFloat(formData.get('duration'))
        };
        resourceData.timeslots.push(timeslot);
        showNotification('success', `Time slot added successfully`);
        e.target.reset();
        updateResourceCounts();
    }));

    safe('class-form', el => el.addEventListener('submit', (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const classData = {
            id: `class_${Date.now()}`,
            name: formData.get('name'),
            subjects: formData.get('subjects').split(',').map(s => s.trim())
        };
        resourceData.classes.push(classData);
        showNotification('success', `Class ${classData.name} added successfully`);
        e.target.reset();
        updateResourceCounts();
    }));

    safe('submit-resources-btn', el => el.addEventListener('click', submitResources));
    safe('load-example-btn',     el => el.addEventListener('click', loadExampleDataset));
    safe('clear-resources-btn',  el => el.addEventListener('click', clearAllForms));
}

/**
 * Submits all collected resource data to the backend via POST /api/resources.
 * Validates that at least one of each resource type has been added before sending.
 * On success, automatically navigates to the Generate section.
 * @async
 */
async function submitResources() {
    // Validate that we have resources
    if (resourceData.teachers.length === 0 || 
        resourceData.subjects.length === 0 || 
        resourceData.rooms.length === 0 || 
        resourceData.timeslots.length === 0 || 
        resourceData.classes.length === 0) {
        showNotification('error', 'Please add at least one of each resource type');
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/resources`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(resourceData)
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to submit resources');
        }

        const result = await response.json();
        _resourcesSubmittedToBackend = true;
        showNotification('success', 'All resources submitted successfully!');
        
        // Switch to generate section
        setTimeout(() => {
            switchSection('generate');
            document.querySelectorAll('.nav-btn').forEach(btn => {
                btn.classList.toggle('active', btn.getAttribute('data-section') === 'generate');
            });
        }, 1000);
        
    } catch (error) {
        showNotification('error', `Error: ${error.message}`);
    }
}

function clearAllForms() {
    document.querySelectorAll('form').forEach(form => form.reset());
    resourceData = {
        teachers: [],
        subjects: [],
        rooms: [],
        timeslots: [],
        classes: []
    };
    _resourcesSubmittedToBackend = false;
    updateResourceCounts();
    showNotification('info', 'All forms cleared');
}

// Fill a single form with one example entry so users can see the format
const _exampleCounters = { teacher: 0, subject: 0, room: 0, timeslot: 0, class: 0 };
const _exampleData = {
    teacher: [
        { name: 'Prof. Vaishali Baviskar', subjects: 's3,s4,s1,s2',    maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Minal Barhate',     subjects: 's5,s6,s7,s9',    maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Swati Joshi',       subjects: 's1,s2,s4,s6',    maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Gopal Upadhye',     subjects: 's7,s9,s10,s11',  maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Shital Dongre',     subjects: 's8,s10,s11,s7',  maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Milind Kulkarni',   subjects: 's7,s8,s9,s11',   maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Viomesh Singh',     subjects: 's1,s2,s3,s5',    maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Sonali Deshmukh',   subjects: 's2,s4,s6,s1,s3', maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' },
        { name: 'Prof. Bhagwan Thorat',    subjects: 's2,s4,s6,s5,s3', maxload: 35, availability: 'slot1,slot2,slot3,slot4,slot5,slot6,slot7,slot8,slot9,slot10,slot11,slot12,slot13,slot14,slot15,slot16,slot17,slot18,slot19,slot20,slot21,slot22,slot23,slot24,slot25,slot26,slot27,slot28,slot29,slot30,slot31,slot32,slot33,slot34,slot35,slot36,slot37,slot38,slot39,slot40,slot41,slot42,slot43,slot44,slot45' }
    ],
    subject: [
        { name: 'OOPs',        hours: 2, type: 'theory',   duration: 1 },
        { name: 'OOPs Lab',    hours: 2, type: 'lab',      duration: 2 },
        { name: 'MFAI',        hours: 2, type: 'theory',   duration: 1 },
        { name: 'MFAI Lab',    hours: 1, type: 'lab',      duration: 2 },
        { name: 'CN',          hours: 2, type: 'theory',   duration: 1 },
        { name: 'CN Lab',      hours: 1, type: 'lab',      duration: 2 },
        { name: 'PAAS',        hours: 2, type: 'theory',   duration: 1 },
        { name: 'DT Tutorial', hours: 1, type: 'tutorial', duration: 1 },
        { name: 'RAAD',        hours: 1, type: 'theory',   duration: 1 },
        { name: 'IP',          hours: 3, type: 'theory',   duration: 1 },
        { name: 'IP Tutorial', hours: 1, type: 'tutorial', duration: 1 }
    ],
    room: [
        { name: '2101-A', capacity: 24, type: 'lab' },
        { name: '2101-B', capacity: 24, type: 'lab' },
        { name: '2101-C', capacity: 24, type: 'lab' },
        { name: '2207-A', capacity: 24, type: 'lab' },
        { name: '2207-B', capacity: 24, type: 'lab' },
        { name: '2207-C', capacity: 24, type: 'lab' },
        { name: '2102',   capacity: 72, type: 'classroom' },
        { name: '2103',   capacity: 72, type: 'classroom' }
    ],
    timeslot: [
        { day: 'monday',    period: 1, start: '09:00', duration: 1 },
        { day: 'monday',    period: 2, start: '10:00', duration: 1 },
        { day: 'monday',    period: 3, start: '11:00', duration: 1 },
        { day: 'tuesday',   period: 1, start: '09:00', duration: 1 },
        { day: 'tuesday',   period: 2, start: '10:00', duration: 1 },
        { day: 'tuesday',   period: 3, start: '11:00', duration: 1 },
        { day: 'wednesday', period: 1, start: '09:00', duration: 1 },
        { day: 'wednesday', period: 2, start: '10:00', duration: 1 },
        { day: 'thursday',  period: 1, start: '09:00', duration: 1 },
        { day: 'thursday',  period: 2, start: '10:00', duration: 1 }
    ],
    class: [
        { name: 'CS-A', subjects: 's1,s2,s3,s7' },
        { name: 'CS-B', subjects: 's4,s5,s6' },
        { name: 'CS-C', subjects: 's1,s5,s7' }
    ]
};

function fillExample(type) {
    const examples = _exampleData[type];
    if (!examples) return;
    const idx = _exampleCounters[type] % examples.length;
    const ex = examples[idx];
    _exampleCounters[type]++;

    if (type === 'teacher') {
        document.getElementById('teacher-name').value = ex.name;
        document.getElementById('teacher-subjects').value = ex.subjects;
        document.getElementById('teacher-maxload').value = ex.maxload;
        document.getElementById('teacher-availability').value = ex.availability;
    } else if (type === 'subject') {
        document.getElementById('subject-name').value = ex.name;
        document.getElementById('subject-hours').value = ex.hours;
        document.getElementById('subject-type').value = ex.type;
        document.getElementById('subject-duration').value = ex.duration;
    } else if (type === 'room') {
        document.getElementById('room-name').value = ex.name;
        document.getElementById('room-capacity').value = ex.capacity;
        document.getElementById('room-type').value = ex.type;
    } else if (type === 'timeslot') {
        document.getElementById('timeslot-day').value = ex.day;
        document.getElementById('timeslot-period').value = ex.period;
        document.getElementById('timeslot-start').value = ex.start;
        document.getElementById('timeslot-duration').value = ex.duration;
    } else if (type === 'class') {
        document.getElementById('class-name').value = ex.name;
        document.getElementById('class-subjects').value = ex.subjects;
    }
    showNotification('info', `Example ${type} filled in. Click Add to save it.`);
}

function loadExampleDataset() {
    resourceData = {
        teachers: [
            { id: 't1', name: 'Prof. Vaishali Baviskar', subjects: ['s3','s4','s1','s2'],       maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't2', name: 'Prof. Minal Barhate',     subjects: ['s5','s6','s7','s9'],       maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't3', name: 'Prof. Swati Joshi',       subjects: ['s1','s2','s4','s6'],       maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't4', name: 'Prof. Gopal Upadhye',     subjects: ['s7','s9','s10','s11'],     maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't5', name: 'Prof. Shital Dongre',     subjects: ['s8','s10','s11','s7'],     maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't6', name: 'Prof. Milind Kulkarni',   subjects: ['s7','s8','s9','s11'],      maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't7', name: 'Prof. Viomesh Singh',     subjects: ['s1','s2','s3','s5'],       maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't8', name: 'Prof. Sonali Deshmukh',   subjects: ['s2','s4','s6','s1','s3'],  maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] },
            { id: 't9', name: 'Prof. Bhagwan Thorat',    subjects: ['s2','s4','s6','s5','s3'],  maxload: 35, availability: ['slot1','slot2','slot3','slot4','slot5','slot6','slot7','slot8','slot9','slot10','slot11','slot12','slot13','slot14','slot15','slot16','slot17','slot18','slot19','slot20','slot21','slot22','slot23','slot24','slot25','slot26','slot27','slot28','slot29','slot30','slot31','slot32','slot33','slot34','slot35','slot36','slot37','slot38','slot39','slot40','slot41','slot42','slot43','slot44','slot45'] }
        ],
        subjects: [
            { id: 's1',  name: 'OOPs',        hours: 2, type: 'theory',   duration: 1 },
            { id: 's2',  name: 'OOPs Lab',    hours: 2, type: 'lab',      duration: 2 },
            { id: 's3',  name: 'MFAI',        hours: 2, type: 'theory',   duration: 1 },
            { id: 's4',  name: 'MFAI Lab',    hours: 1, type: 'lab',      duration: 2 },
            { id: 's5',  name: 'CN',          hours: 2, type: 'theory',   duration: 1 },
            { id: 's6',  name: 'CN Lab',      hours: 1, type: 'lab',      duration: 2 },
            { id: 's7',  name: 'PAAS',        hours: 2, type: 'theory',   duration: 1 },
            { id: 's8',  name: 'DT Tutorial', hours: 1, type: 'tutorial', duration: 1 },
            { id: 's9',  name: 'RAAD',        hours: 1, type: 'theory',   duration: 1 },
            { id: 's10', name: 'IP',          hours: 3, type: 'theory',   duration: 1 },
            { id: 's11', name: 'IP Tutorial', hours: 1, type: 'tutorial', duration: 1 }
        ],
        rooms: [
            // Labs: 18 needed (c3-c8 each have s2,s4,s6 = 3 lab sessions × 6 classes)
            { id: 'r1',  name: '2101-A', capacity: 24, type: 'lab' },
            { id: 'r2',  name: '2101-B', capacity: 24, type: 'lab' },
            { id: 'r3',  name: '2101-C', capacity: 24, type: 'lab' },
            { id: 'r4',  name: '2101-D', capacity: 24, type: 'lab' },
            { id: 'r5',  name: '2101-E', capacity: 24, type: 'lab' },
            { id: 'r6',  name: '2101-F', capacity: 24, type: 'lab' },
            { id: 'r7',  name: '2207-A', capacity: 24, type: 'lab' },
            { id: 'r8',  name: '2207-B', capacity: 24, type: 'lab' },
            { id: 'r9',  name: '2207-C', capacity: 24, type: 'lab' },
            { id: 'r10', name: '2207-D', capacity: 24, type: 'lab' },
            { id: 'r11', name: '2207-E', capacity: 24, type: 'lab' },
            { id: 'r12', name: '2207-F', capacity: 24, type: 'lab' },
            { id: 'r13', name: '2301-A', capacity: 24, type: 'lab' },
            { id: 'r14', name: '2301-B', capacity: 24, type: 'lab' },
            { id: 'r15', name: '2301-C', capacity: 24, type: 'lab' },
            { id: 'r16', name: '2301-D', capacity: 24, type: 'lab' },
            { id: 'r17', name: '2301-E', capacity: 24, type: 'lab' },
            { id: 'r18', name: '2301-F', capacity: 24, type: 'lab' },
            // Classrooms: 12 needed (c1+c2 each have s1,s3,s5,s7,s9,s10 = 6 theory × 2)
            { id: 'r19', name: '2102',   capacity: 72, type: 'classroom' },
            { id: 'r20', name: '2103',   capacity: 72, type: 'classroom' },
            { id: 'r21', name: '2104',   capacity: 72, type: 'classroom' },
            { id: 'r22', name: '2105',   capacity: 72, type: 'classroom' },
            { id: 'r23', name: '2106',   capacity: 72, type: 'classroom' },
            { id: 'r24', name: '2107',   capacity: 72, type: 'classroom' },
            { id: 'r25', name: '2108',   capacity: 72, type: 'classroom' },
            { id: 'r26', name: '2201',   capacity: 72, type: 'classroom' },
            { id: 'r27', name: '2202',   capacity: 72, type: 'classroom' },
            { id: 'r28', name: '2203',   capacity: 72, type: 'classroom' },
            { id: 'r29', name: '2204',   capacity: 72, type: 'classroom' },
            { id: 'r30', name: '2205',   capacity: 72, type: 'classroom' }
        ],
        timeslots: [
            { id: 'slot1',  day: 'monday',    period: 1, start: '08:00', duration: 1 },
            { id: 'slot2',  day: 'monday',    period: 2, start: '09:00', duration: 1 },
            { id: 'slot3',  day: 'monday',    period: 3, start: '10:00', duration: 1 },
            { id: 'slot4',  day: 'monday',    period: 4, start: '11:00', duration: 1 },
            { id: 'slot5',  day: 'monday',    period: 5, start: '12:00', duration: 1 },
            { id: 'slot6',  day: 'monday',    period: 6, start: '14:00', duration: 1 },
            { id: 'slot7',  day: 'monday',    period: 7, start: '15:00', duration: 1 },
            { id: 'slot8',  day: 'monday',    period: 8, start: '16:00', duration: 1 },
            { id: 'slot9',  day: 'monday',    period: 9, start: '17:00', duration: 1 },
            { id: 'slot10', day: 'tuesday',   period: 1, start: '08:00', duration: 1 },
            { id: 'slot11', day: 'tuesday',   period: 2, start: '09:00', duration: 1 },
            { id: 'slot12', day: 'tuesday',   period: 3, start: '10:00', duration: 1 },
            { id: 'slot13', day: 'tuesday',   period: 4, start: '11:00', duration: 1 },
            { id: 'slot14', day: 'tuesday',   period: 5, start: '12:00', duration: 1 },
            { id: 'slot15', day: 'tuesday',   period: 6, start: '14:00', duration: 1 },
            { id: 'slot16', day: 'tuesday',   period: 7, start: '15:00', duration: 1 },
            { id: 'slot17', day: 'tuesday',   period: 8, start: '16:00', duration: 1 },
            { id: 'slot18', day: 'tuesday',   period: 9, start: '17:00', duration: 1 },
            { id: 'slot19', day: 'wednesday', period: 1, start: '08:00', duration: 1 },
            { id: 'slot20', day: 'wednesday', period: 2, start: '09:00', duration: 1 },
            { id: 'slot21', day: 'wednesday', period: 3, start: '10:00', duration: 1 },
            { id: 'slot22', day: 'wednesday', period: 4, start: '11:00', duration: 1 },
            { id: 'slot23', day: 'wednesday', period: 5, start: '12:00', duration: 1 },
            { id: 'slot24', day: 'wednesday', period: 6, start: '14:00', duration: 1 },
            { id: 'slot25', day: 'wednesday', period: 7, start: '15:00', duration: 1 },
            { id: 'slot26', day: 'wednesday', period: 8, start: '16:00', duration: 1 },
            { id: 'slot27', day: 'wednesday', period: 9, start: '17:00', duration: 1 },
            { id: 'slot28', day: 'thursday',  period: 1, start: '08:00', duration: 1 },
            { id: 'slot29', day: 'thursday',  period: 2, start: '09:00', duration: 1 },
            { id: 'slot30', day: 'thursday',  period: 3, start: '10:00', duration: 1 },
            { id: 'slot31', day: 'thursday',  period: 4, start: '11:00', duration: 1 },
            { id: 'slot32', day: 'thursday',  period: 5, start: '12:00', duration: 1 },
            { id: 'slot33', day: 'thursday',  period: 6, start: '14:00', duration: 1 },
            { id: 'slot34', day: 'thursday',  period: 7, start: '15:00', duration: 1 },
            { id: 'slot35', day: 'thursday',  period: 8, start: '16:00', duration: 1 },
            { id: 'slot36', day: 'thursday',  period: 9, start: '17:00', duration: 1 },
            { id: 'slot37', day: 'friday',    period: 1, start: '08:00', duration: 1 },
            { id: 'slot38', day: 'friday',    period: 2, start: '09:00', duration: 1 },
            { id: 'slot39', day: 'friday',    period: 3, start: '10:00', duration: 1 },
            { id: 'slot40', day: 'friday',    period: 4, start: '11:00', duration: 1 },
            { id: 'slot41', day: 'friday',    period: 5, start: '12:00', duration: 1 },
            { id: 'slot42', day: 'friday',    period: 6, start: '14:00', duration: 1 },
            { id: 'slot43', day: 'friday',    period: 7, start: '15:00', duration: 1 },
            { id: 'slot44', day: 'friday',    period: 8, start: '16:00', duration: 1 },
            { id: 'slot45', day: 'friday',    period: 9, start: '17:00', duration: 1 }
        ],
        classes: [
            { id: 'c1', name: 'AIDS-A', subjects: ['s1','s3','s5','s7','s9','s10'] },
            { id: 'c2', name: 'AIDS-B', subjects: ['s1','s3','s5','s7','s9','s10'] },
            { id: 'c3', name: 'A1',     subjects: ['s2','s4','s6','s8','s11'] },
            { id: 'c4', name: 'A2',     subjects: ['s2','s4','s6','s8','s11'] },
            { id: 'c5', name: 'A3',     subjects: ['s2','s4','s6','s8','s11'] },
            { id: 'c6', name: 'B1',     subjects: ['s2','s4','s6','s8','s11'] },
            { id: 'c7', name: 'B2',     subjects: ['s2','s4','s6','s8','s11'] },
            { id: 'c8', name: 'B3',     subjects: ['s2','s4','s6','s8','s11'] }
        ]
    };
    updateResourceCounts();
    showNotification('success', 'Example dataset loaded! Click "Submit All Resources to Backend" to proceed.');
}

// ============================================
// Timetable Generation
// ============================================

function initializeGenerateSection() {
    const btn = document.getElementById('generate-btn');
    if (btn) btn.addEventListener('click', generateTimetable);
}

// ============================================================
// Generate Section — Resource Summary + Quick Edit
// ============================================================

/** Sync the mini resource counts in the generate section */
function updateGenResourceCounts() {
    const types = ['teachers', 'subjects', 'rooms', 'timeslots', 'classes'];
    types.forEach(t => {
        const el = document.getElementById(`gen-count-${t}`);
        if (el) el.textContent = resourceData[t].length;
    });
}

/** Toggle the inline edit panel */
function toggleGenEdit() {
    const panel = document.getElementById('gen-edit-panel');
    const btn   = document.getElementById('gen-edit-toggle-btn');
    if (panel.style.display === 'none') {
        panel.style.display = 'block';
        btn.textContent = '✖ Close Editor';
        renderGenTab('teachers');
    } else {
        panel.style.display = 'none';
        btn.textContent = '✏️ Edit Resources';
    }
}

let _currentGenTab = 'teachers';

/** Switch the active tab in the edit panel */
function switchGenTab(type) {
    _currentGenTab = type;
    document.querySelectorAll('.gen-tab-btn').forEach(b => {
        b.classList.toggle('active', b.textContent.toLowerCase().includes(type.replace('timeslots','slot')));
    });
    renderGenTab(type);
}

/** Render the list of items for the given resource type */
function renderGenTab(type) {
    const content = document.getElementById('gen-edit-content');
    const items   = resourceData[type] || [];

    if (items.length === 0) {
        content.innerHTML = `<p class="gen-edit-empty">No ${type} added yet.</p>`;
        return;
    }

    content.innerHTML = items.map((item, idx) => {
        const label = getItemLabel(type, item);
        const detail = getItemDetail(type, item);
        const isReadOnly = (type === 'rooms');
        return `<div class="gen-edit-row${isReadOnly ? ' gen-edit-row--readonly' : ''}">
            <div class="gen-edit-row-info">
                <strong>${label}</strong>
                <small>${detail}</small>
            </div>
            ${isReadOnly
                ? `<span class="gen-readonly-badge">🔒 Fixed</span>`
                : `<button class="gen-delete-btn" onclick="deleteGenItem('${type}', ${idx})">✕ Remove</button>`
            }
        </div>`;
    }).join('');
}

function getItemLabel(type, item) {
    switch (type) {
        case 'teachers':   return item.name || item.id;
        case 'subjects':   return item.name || item.id;
        case 'rooms':      return item.name || item.id;
        case 'timeslots':  return `${item.day || ''} P${item.period || ''} (${item.start || ''})`;
        case 'classes':    return item.name || item.id;
        default:           return item.id || JSON.stringify(item);
    }
}

function getItemDetail(type, item) {
    switch (type) {
        case 'teachers':  return `Subjects: ${(item.subjects || []).join(', ')} | Max load: ${item.maxload}`;
        case 'subjects':  return `${item.type} | ${item.hours}h/week`;
        case 'rooms':     return `${item.type} | Capacity: ${item.capacity}`;
        case 'timeslots': return `Duration: ${item.duration}h`;
        case 'classes':   return `Subjects: ${(item.subjects || []).join(', ')}`;
        default:          return '';
    }
}

/** Delete an item from resourceData and re-render */
function deleteGenItem(type, idx) {
    if (type === 'rooms') {
        showNotification('error', 'Rooms are fixed and cannot be removed.');
        return;
    }
    resourceData[type].splice(idx, 1);
    updateResourceCounts();
    updateGenResourceCounts();
    renderGenTab(type);
    showNotification('info', `Removed item from ${type}. Re-submit to backend to apply.`);
}

/** Re-submit the edited resourceData to the backend */
async function resubmitResources() {
    const types = ['teachers', 'subjects', 'rooms', 'timeslots', 'classes'];
    const empty = types.filter(t => resourceData[t].length === 0);
    if (empty.length > 0) {
        showNotification('error', `Cannot submit: ${empty.join(', ')} is empty.`);
        return;
    }
    try {
        const response = await fetch(`${API_BASE_URL}/resources`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(resourceData)
        });
        const result = await response.json();
        if (!response.ok) throw new Error(result.message || 'Failed');
        _resourcesSubmittedToBackend = true;
        showNotification('success', 'Resources re-submitted successfully!');
    } catch (err) {
        showNotification('error', `Re-submit failed: ${err.message}`);
    }
}

/**
 * Triggers timetable generation via POST /api/generate.
 * Displays a loading indicator during generation, then renders the result.
 * Also loads quality score and conflict highlights after successful generation.
 * @async
 */
async function generateTimetable() {
    const generateBtn      = document.getElementById('generate-btn');
    const loadingIndicator = document.getElementById('loading-indicator');
    const resultBox        = document.getElementById('generation-result');
    const genAnywayBtn     = document.getElementById('generate-anyway-btn');

    // Disable whichever button triggered this
    if (generateBtn)  generateBtn.disabled  = true;
    if (genAnywayBtn) genAnywayBtn.disabled = true;
    if (loadingIndicator) loadingIndicator.style.display = 'block';
    if (resultBox)    resultBox.style.display = 'none';
    if (genAnywayBtn) genAnywayBtn.innerHTML = '<span class="btn-icon">⏳</span> Generating…';

    try {
        // Auto-submit resources if not yet sent to backend
        if (!_resourcesSubmittedToBackend) {
            const types = ['teachers','subjects','rooms','timeslots','classes'];
            const hasData = types.every(t => resourceData[t].length > 0);
            if (!hasData) {
                throw new Error('No resources loaded. Please load the example dataset or add resources first.');
            }
            showNotification('info', 'Submitting resources to backend…');
            const subResp = await fetch(`${API_BASE_URL}/resources`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(resourceData)
            });
            if (!subResp.ok) {
                const e = await subResp.json().catch(() => ({}));
                throw new Error(e.message || 'Failed to submit resources');
            }
            _resourcesSubmittedToBackend = true;
        }

        const response = await fetch(`${API_BASE_URL}/generate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to generate timetable');
        }

        const result = await response.json();
        currentTimetable = result.timetable;
        currentReliability = result.reliability;

        if (resultBox) {
            resultBox.className = 'result-box success';
            resultBox.textContent = 'Timetable generated successfully!';
            resultBox.style.display = 'block';
        }
        showNotification('success', 'Timetable generated successfully!');

        setTimeout(() => {
            switchSection('visualize');
            document.querySelectorAll('.nav-btn').forEach(btn => {
                btn.classList.toggle('active', btn.getAttribute('data-section') === 'visualize');
            });
            renderTimetable(currentTimetable);
            updateReliabilityDisplay(currentReliability);
            checkAndHighlightConflicts();
            const exportPdf  = document.getElementById('export-pdf-btn');
            const exportCsv  = document.getElementById('export-csv-btn');
            const exportJson = document.getElementById('export-json-btn');
            if (exportPdf)  exportPdf.disabled  = false;
            if (exportCsv)  exportCsv.disabled  = false;
            if (exportJson) exportJson.disabled = false;
            // Auto-load quality score and search stats
            if (typeof loadQualityScore === 'function') loadQualityScore();
            setTimeout(() => { if (typeof loadSearchStatistics === 'function') loadSearchStatistics(); }, 2000);
        }, 1000);

    } catch (error) {
        if (resultBox) {
            resultBox.className = 'result-box error';
            resultBox.textContent = `Error: ${error.message}`;
            resultBox.style.display = 'block';
        }
        showNotification('error', `Generation failed: ${error.message}`);
    } finally {
        if (generateBtn)  generateBtn.disabled  = false;
        if (genAnywayBtn) {
            genAnywayBtn.disabled = false;
            genAnywayBtn.innerHTML = '<span class="btn-icon">🚀</span> Generate Anyway';
        }
        if (loadingIndicator) loadingIndicator.style.display = 'none';
    }
}

// ============================================
// Timetable Visualization
// ============================================

function initializeVisualizationSection() {
    const safe = (id, fn) => { const el = document.getElementById(id); if (el) fn(el); };
    safe('export-pdf-btn',  el => el.addEventListener('click', () => exportTimetable('pdf')));
    safe('export-csv-btn',  el => el.addEventListener('click', () => exportTimetable('csv')));
    safe('export-json-btn', el => el.addEventListener('click', () => exportTimetable('json')));
}

/**
 * Renders the timetable grid into the visualization section.
 * @param {Object} timetable - Timetable object with slots and assignments arrays.
 */
function renderTimetable(timetable) {
    const gridContainer = document.getElementById('timetable-grid');

    if (!timetable) {
        gridContainer.innerHTML = '<p class="empty-state">No timetable data available</p>';
        return;
    }

    const slots       = timetable.timeslots || timetable.slots || [];
    const assignments = timetable.assignments || [];

    if (assignments.length === 0) {
        gridContainer.innerHTML = '<p class="empty-state">No assignments in timetable</p>';
        return;
    }

    // Build lookup maps
    const slotById = {};
    slots.forEach(s => { slotById[s.id] = s; });

    // Resolve display names
    function resolveName(type, id) {
        if (!id) return '—';
        const items = (typeof resourceData !== 'undefined' && resourceData[type]) || [];
        const found = items.find(x => x.id === id);
        return found ? (found.name || id) : id;
    }

    // Get unique days in order
    const dayOrder = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    const usedDays = [...new Set(slots.map(s => (s.day||'').toLowerCase()))].sort((a,b) => dayOrder.indexOf(a) - dayOrder.indexOf(b));

    // Get unique periods sorted
    const usedPeriods = [...new Set(slots.map(s => s.period))].sort((a,b) => a - b);

    // Build slot lookup: day+period -> slot
    const slotByDayPeriod = {};
    slots.forEach(s => { slotByDayPeriod[`${(s.day||'').toLowerCase()}__${s.period}`] = s; });

    // Build assignment lookup: slotId -> [assignments]
    const assignBySlot = {};
    assignments.forEach(a => {
        if (!assignBySlot[a.slot_id]) assignBySlot[a.slot_id] = [];
        assignBySlot[a.slot_id].push(a);
    });

    // Get time labels for period headers
    const periodTimes = {};
    usedPeriods.forEach(p => {
        const slot = slots.find(s => s.period === p);
        periodTimes[p] = slot ? (slot.start_time || slot.start || `P${p}`) : `P${p}`;
    });

    // Build table HTML
    let html = '<table class="tt-table"><thead><tr>';
    html += '<th class="tt-day-header">Day / Time</th>';
    usedPeriods.forEach(p => {
        html += `<th class="tt-period-header"><div>P${p}</div><small>${periodTimes[p]}</small></th>`;
    });
    html += '</tr></thead><tbody>';

    usedDays.forEach(day => {
        html += `<tr><td class="tt-day-cell">${day.charAt(0).toUpperCase() + day.slice(1)}</td>`;
        usedPeriods.forEach(p => {
            const slot = slotByDayPeriod[`${day}__${p}`];
            const cellAssignments = slot ? (assignBySlot[slot.id] || []) : [];
            if (cellAssignments.length === 0) {
                html += '<td class="tt-empty">—</td>';
            } else {
                html += '<td class="tt-cell">';
                cellAssignments.forEach(a => {
                    const cls     = resolveName('classes',  a.class_id);
                    const subj    = resolveName('subjects', a.subject_id);
                    const teacher = resolveName('teachers', a.teacher_id);
                    const room    = resolveName('rooms',    a.room_id);
                    html += `<div class="tt-entry">
                        <strong>${cls}</strong>
                        <div class="tt-subject">${subj}</div>
                        <small class="tt-teacher">${teacher}</small>
                        <small class="tt-room">${room}</small>
                    </div>`;
                });
                html += '</td>';
            }
        });
        html += '</tr>';
    });

    html += '</tbody></table>';

    // Reset grid styles and inject table
    gridContainer.style.gridTemplateColumns = '';
    gridContainer.style.display = 'block';
    gridContainer.innerHTML = html;
}

/** Resolve an ID to a display name using resourceData, falling back to the raw id */
function _resolveId(type, id) {
    if (!id) return '—';
    const items = (typeof resourceData !== 'undefined' && resourceData[type]) || [];
    const found = items.find(x => x.id === id);
    return found ? (found.name || id) : id;
}

/**
 * Updates the reliability score display panel.
 * @param {number|null} reliability - Score between 0.0 and 1.0, or null if unavailable.
 */
function updateReliabilityDisplay(reliability) {
    if (!reliability && reliability !== 0) {
        return;
    }
    
    const scoreElement = document.getElementById('reliability-score');
    const barFill = document.getElementById('reliability-bar-fill');
    const riskLevel = document.getElementById('risk-level');
    
    // Update score
    const scorePercent = (reliability * 100).toFixed(1);
    scoreElement.textContent = `${scorePercent}%`;
    
    // Update bar
    barFill.style.width = `${scorePercent}%`;
    
    // Color code based on reliability
    if (reliability >= 0.95) {
        barFill.style.backgroundColor = 'var(--success-color)';
        riskLevel.textContent = 'Low';
        riskLevel.className = 'risk-badge low';
    } else if (reliability >= 0.85) {
        barFill.style.backgroundColor = 'var(--warning-color)';
        riskLevel.textContent = 'Medium';
        riskLevel.className = 'risk-badge medium';
    } else if (reliability >= 0.70) {
        barFill.style.backgroundColor = 'var(--danger-color)';
        riskLevel.textContent = 'High';
        riskLevel.className = 'risk-badge high';
    } else {
        barFill.style.backgroundColor = '#c0392b';
        riskLevel.textContent = 'Critical';
        riskLevel.className = 'risk-badge critical';
    }
}

/**
 * Fetches conflicts from GET /api/conflicts and highlights conflicting cells in the grid.
 * @async
 */
async function checkAndHighlightConflicts() {
    try {
        const response = await fetch(`${API_BASE_URL}/conflicts`);
        
        if (!response.ok) {
            console.error('Failed to fetch conflicts');
            return;
        }
        
        const result = await response.json();
        const conflicts = result.conflicts || [];
        
        if (conflicts.length > 0) {
            // Show conflicts panel
            const conflictsPanel = document.getElementById('conflicts-panel');
            const conflictsList = document.getElementById('conflicts-list');
            
            conflictsPanel.style.display = 'block';
            conflictsList.innerHTML = '';
            
            conflicts.forEach(conflict => {
                const li = document.createElement('li');
                li.textContent = conflict.description || JSON.stringify(conflict);
                conflictsList.appendChild(li);
                
                // Highlight conflicting cells
                if (conflict.room !== undefined && conflict.slot !== undefined) {
                    const cell = document.querySelector(
                        `.grid-cell[data-room="${conflict.room}"][data-slot="${conflict.slot}"]`
                    );
                    if (cell) {
                        cell.classList.add('conflict');
                    }
                }
            });

            // Reveal the suggestions panel so the user can load fixes
            document.getElementById('suggestions-panel').style.display = 'block';
        } else {
            // Hide conflicts and suggestions panels if no conflicts
            document.getElementById('conflicts-panel').style.display = 'none';
            document.getElementById('suggestions-panel').style.display = 'none';
        }
        
    } catch (error) {
        console.error('Error checking conflicts:', error);
    }
}

// ============================================
// Explanation Modal
// ============================================

function initializeModal() {
    const modal    = document.getElementById('explanation-modal');
    const closeBtn = document.getElementById('modal-close-btn');
    const okBtn    = document.getElementById('modal-ok-btn');

    if (closeBtn) closeBtn.addEventListener('click', closeModal);
    if (okBtn)    okBtn.addEventListener('click', closeModal);
    if (modal)    modal.addEventListener('click', (e) => { if (e.target === modal) closeModal(); });
}

/**
 * Fetches and displays the AI explanation for a timetable assignment.
 * Opens the explanation modal with XAI reasoning steps.
 * @async
 * @param {Object} assignment - Assignment object with class_id, subject_id, teacher_id, room_id, slot_id.
 */
async function showExplanation(assignment) {
    const modal = document.getElementById('explanation-modal');
    const summaryEl = document.getElementById('explanation-summary');
    const qualityPanel = document.getElementById('xai-quality-panel');
    const stepsPanel = document.getElementById('xai-steps-panel');
    const fallbackEl = document.getElementById('explanation-content');

    // Reset panels
    summaryEl.textContent = '';
    qualityPanel.style.display = 'none';
    stepsPanel.style.display = 'none';
    fallbackEl.innerHTML = '<p>Loading explanation...</p>';
    modal.classList.add('active');

    try {
        // Try the detailed XAI endpoint first
        const payload = {
            class_id:   assignment.class_id   || assignment.class   || '',
            subject_id: assignment.subject_id || assignment.subject || '',
            teacher_id: assignment.teacher_id || assignment.teacher || '',
            room_id:    assignment.room_id    || assignment.room    || '',
            slot_id:    assignment.slot_id    || assignment.slot    || ''
        };

        const response = await fetch(`${API_BASE_URL}/explain_detailed`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (response.ok) {
            const result = await response.json();
            if (result.status === 'success' && result.explanation) {
                displayXAIExplanation(result.explanation);
                fallbackEl.innerHTML = '';
                return;
            }
        }

        // Fallback to basic explain endpoint
        const basicResponse = await fetch(`${API_BASE_URL}/explain`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ assignment })
        });
        const basicResult = await basicResponse.json();
        fallbackEl.innerHTML = `<p>${basicResult.explanation || 'No explanation available.'}</p>`;

    } catch (error) {
        fallbackEl.innerHTML = `<p class="error">Error loading explanation: ${error.message}</p>`;
    }
}

/**
 * displayXAIExplanation(explanation)
 * Renders a structured XAI explanation object into the modal.
 * @param {Object} explanation - { summary, steps, quality, quality_breakdown }
 */
function displayXAIExplanation(explanation) {
    // Summary
    const summaryEl = document.getElementById('explanation-summary');
    summaryEl.textContent = explanation.summary || '';

    // Quality score
    const qualityPanel = document.getElementById('xai-quality-panel');
    if (explanation.quality !== undefined) {
        const pct = Math.round(explanation.quality * 100);
        document.getElementById('xai-quality-value').textContent = `${pct}%`;

        const breakdown = explanation.quality_breakdown || {};
        const metrics = [
            { key: 'teacher_workload', label: 'Teacher Workload' },
            { key: 'room_utilization', label: 'Room Utilization' },
            { key: 'time_preference',  label: 'Time Preference'  }
        ];

        const breakdownEl = document.getElementById('xai-quality-breakdown');
        breakdownEl.innerHTML = '';
        metrics.forEach(({ key, label }) => {
            const val = breakdown[key] !== undefined ? breakdown[key] : 0;
            const valPct = Math.round(val * 100);
            const cls = valPct >= 70 ? 'good' : valPct >= 40 ? 'medium' : 'poor';
            breakdownEl.insertAdjacentHTML('beforeend', `
                <div class="xai-metric">
                    <span class="xai-metric-label">${label}</span>
                    <div class="xai-metric-bar-track">
                        <div class="xai-metric-bar-fill ${cls}" style="width:${valPct}%"></div>
                    </div>
                    <span class="xai-metric-pct">${valPct}%</span>
                </div>
            `);
        });
        qualityPanel.style.display = 'block';
    }

    // Reasoning steps
    const stepsPanel = document.getElementById('xai-steps-panel');
    const steps = explanation.steps || [];
    if (steps.length > 0) {
        const stepsList = document.getElementById('xai-steps-list');
        stepsList.innerHTML = '';
        steps.forEach(step => {
            const ok = step.satisfied === true || step.satisfied === 'true';
            const icon = ok ? '✓' : '✗';
            const cls  = ok ? 'satisfied' : 'violated';
            const typeLabel = (step.type || '').replace(/_/g, ' ');
            stepsList.insertAdjacentHTML('beforeend', `
                <li class="xai-step ${cls}">
                    <span class="xai-step-icon">${icon}</span>
                    <span class="xai-step-type">${typeLabel}</span>
                    <span class="xai-step-desc">${step.description || ''}</span>
                </li>
            `);
        });
        stepsPanel.style.display = 'block';
    }
}

function closeModal() {
    const modal = document.getElementById('explanation-modal');
    modal.classList.remove('active');
}

// ============================================
// Export Functionality
// ============================================

/**
 * Exports the current timetable in the specified format via GET /api/export.
 * @async
 * @param {string} format - Export format: 'json', 'csv', or 'text'.
 */
function exportTimetable(format) {
    if (!currentTimetable) {
        showNotification('error', 'Generate a timetable first before exporting.');
        return;
    }
    if (format === 'json') _exportJSON();
    else if (format === 'csv') _exportCSV();
    else if (format === 'pdf') _exportPDF();
}

function _downloadBlob(content, filename, mimeType) {
    const blob = new Blob([content], { type: mimeType });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href = url; a.download = filename;
    document.body.appendChild(a); a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

function _exportJSON() {
    _downloadBlob(JSON.stringify(currentTimetable, null, 2), 'timetable.json', 'application/json');
    showNotification('success', 'Timetable exported as JSON');
}

function _exportCSV() {
    const assignments = currentTimetable.assignments || [];
    const slots   = {};
    (currentTimetable.slots || currentTimetable.timeslots || []).forEach(s => { slots[s.id] = s; });
    const rooms   = {};
    (currentTimetable.rooms || []).forEach(r => { rooms[r.id] = r; });

    const header = 'Day,Period,Start,Room,Class,Subject,Teacher';
    const rows = assignments.map(a => {
        const slot    = slots[a.slot_id]    || {};
        const room    = rooms[a.room_id]    || {};
        const day     = slot.day            || a.slot_id;
        const period  = slot.period         || '';
        const start   = slot.start_time || slot.start || '';
        const roomName= room.name           || a.room_id;
        const cls     = _resolveId('classes',  a.class_id);
        const subj    = _resolveId('subjects', a.subject_id);
        const teacher = _resolveId('teachers', a.teacher_id);
        return [day, period, start, roomName, cls, subj, teacher].map(v => `"${v}"`).join(',');
    });
    _downloadBlob([header, ...rows].join('\n'), 'timetable.csv', 'text/csv');
    showNotification('success', 'Timetable exported as CSV');
}

function _exportPDF() {
    // Remove any leftover print style from a previous call
    const existing = document.getElementById('__print_style__');
    if (existing) existing.remove();

    const printStyle = document.createElement('style');
    printStyle.id = '__print_style__';
    printStyle.textContent = `
        @media print {
            body > * { display: none !important; }
            #visualize-section { display: block !important; }
            .nav-btn, .export-panel, .reliability-panel,
            .conflicts-panel, .suggestions-panel, .quality-panel { display: none !important; }
            .timetable-container { display: block !important; }
            header, footer, .notification-container { display: none !important; }
        }`;
    document.head.appendChild(printStyle);

    // Clean up after printing using the afterprint event (reliable across browsers)
    const cleanup = () => {
        const s = document.getElementById('__print_style__');
        if (s) s.remove();
        window.removeEventListener('afterprint', cleanup);
    };
    window.addEventListener('afterprint', cleanup);

    window.print();
    showNotification('success', 'Print dialog opened — save as PDF');
}

// ============================================
// Notification System
// ============================================

/**
 * Displays a toast notification to the user.
 * @param {string} type - Notification type: 'success', 'error', 'warning', or 'info'.
 * @param {string} message - The message to display.
 */
function showNotification(type, message) {
    const container = document.getElementById('notification-container');
    if (!container) { console.warn('notification-container not found'); return; }
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    // Add icon based on type
    const icons = {
        success: '✓',
        error: '✗',
        info: 'ℹ',
        warning: '⚠'
    };
    
    notification.innerHTML = `
        <span style="font-size: 1.2rem; font-weight: bold;">${icons[type] || ''}</span>
        <span>${message}</span>
    `;
    
    container.appendChild(notification);
    
    // Auto-dismiss after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideInRight 0.3s ease reverse';
        setTimeout(() => {
            if (container.contains(notification)) container.removeChild(notification);
        }, 300);
    }, 3000);
}

// ============================================
// Feature 2: Smart Conflict Suggestion System
// ============================================

/**
 * Wire up the "Load Suggestions" button once the DOM is ready.
 * Called from the existing DOMContentLoaded handler via initializeConflictSuggestions().
 */
function initializeConflictSuggestions() {
    const btn = document.getElementById('load-suggestions-btn');
    if (btn) {
        btn.addEventListener('click', loadConflictSuggestions);
    }
}

/**
 * loadConflictSuggestions()
 * Fetches GET /api/suggest_fixes and renders the results.
 */
async function loadConflictSuggestions() {
    const panel = document.getElementById('suggestions-panel');
    const list  = document.getElementById('suggestions-list');

    list.innerHTML = '<p class="suggestions-empty">Loading suggestions…</p>';
    panel.style.display = 'block';

    try {
        const response = await fetch(`${API_BASE_URL}/suggest_fixes`);

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to load suggestions');
        }

        const result = await response.json();
        const conflicts = result.conflicts || [];

        displayConflictSuggestions(conflicts);

    } catch (error) {
        list.innerHTML = `<p class="suggestions-empty" style="color:var(--danger-color)">
            Error: ${error.message}
        </p>`;
        showNotification('error', `Could not load suggestions: ${error.message}`);
    }
}

/**
 * displayConflictSuggestions(conflicts)
 * Renders the list of conflicts with their fix suggestions.
 *
 * @param {Array} conflicts - Array of conflict objects from the API.
 */
function displayConflictSuggestions(conflicts) {
    const list = document.getElementById('suggestions-list');
    list.innerHTML = '';

    if (!conflicts || conflicts.length === 0) {
        list.innerHTML = '<p class="suggestions-empty">No conflicts detected – nothing to fix!</p>';
        return;
    }

    conflicts.forEach((conflict, conflictIdx) => {
        const card = document.createElement('div');
        card.className = 'conflict-suggestion-card';

        // Build a human-readable title
        let title = '';
        let meta  = '';
        if (conflict.type === 'teacher_conflict') {
            title = `Teacher Conflict: ${conflict.teacher_id}`;
            meta  = `Slot: ${conflict.slot_id} | Sessions: ${(conflict.sessions || []).join(', ')}`;
        } else if (conflict.type === 'room_conflict') {
            title = `Room Conflict: ${conflict.room_id}`;
            meta  = `Slot: ${conflict.slot_id} | Sessions: ${(conflict.sessions || []).join(', ')}`;
        } else {
            title = `Conflict #${conflictIdx + 1}`;
        }

        const suggestions = conflict.suggestions || [];

        card.innerHTML = `
            <div class="conflict-title">${title}</div>
            <div class="conflict-meta">${meta}</div>
            <div class="fix-list" id="fix-list-${conflictIdx}"></div>
        `;

        list.appendChild(card);

        const fixList = document.getElementById(`fix-list-${conflictIdx}`);

        if (suggestions.length === 0) {
            fixList.innerHTML = '<p class="suggestions-empty">No automatic fixes available for this conflict.</p>';
        } else {
            suggestions.forEach((suggestion, fixIdx) => {
                const item = document.createElement('div');
                item.className = 'fix-item';

                const badgeClass = (suggestion.fix_type || '').replace(/\s+/g, '_');

                item.innerHTML = `
                    <span class="fix-type-badge ${badgeClass}">
                        ${(suggestion.fix_type || 'fix').replace(/_/g, ' ')}
                    </span>
                    <span class="fix-description">${suggestion.description || ''}</span>
                    <button class="btn-apply-fix"
                            data-conflict="${conflictIdx}"
                            data-fix="${fixIdx}"
                            aria-label="Apply fix: ${suggestion.description || ''}">
                        Apply Fix
                    </button>
                `;

                // Store the full suggestion object on the button for easy retrieval
                const applyBtn = item.querySelector('.btn-apply-fix');
                applyBtn._suggestion = suggestion;
                applyBtn.addEventListener('click', () => applyFix(suggestion, applyBtn));

                fixList.appendChild(item);
            });
        }
    });
}

/**
 * applyFix(suggestion, buttonEl)
 * Posts the chosen fix to POST /api/apply_fix and refreshes the timetable view.
 *
 * @param {Object} suggestion - The fix suggestion object { fix_type, description, fix_data }.
 * @param {HTMLElement} buttonEl - The button that was clicked (used to show loading state).
 */
async function applyFix(suggestion, buttonEl) {
    if (!suggestion) return;

    // Disable button while applying
    buttonEl.disabled = true;
    buttonEl.textContent = 'Applying…';

    try {
        const payload = {
            fix_type:    suggestion.fix_type    || '',
            description: suggestion.description || '',
            fix_data:    suggestion.fix_data    || {}
        };

        const response = await fetch(`${API_BASE_URL}/apply_fix`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to apply fix');
        }

        const result = await response.json();

        // Update global state
        if (result.timetable) {
            currentTimetable  = result.timetable;
        }
        if (result.reliability !== undefined) {
            currentReliability = result.reliability;
        }

        showNotification('success', 'Fix applied – timetable updated');

        // Refresh the visualisation
        if (currentTimetable) {
            renderTimetable(currentTimetable);
        }
        if (currentReliability !== null) {
            updateReliabilityDisplay(currentReliability);
        }
        checkAndHighlightConflicts();

        // Reload suggestions to reflect the updated state
        loadConflictSuggestions();

    } catch (error) {
        showNotification('error', `Fix failed: ${error.message}`);
        buttonEl.disabled = false;
        buttonEl.textContent = 'Apply Fix';
    }
}

// ============================================
// Feature 3: Scenario Simulation
// ============================================

// State for the last simulated timetable (used for comparison)
let lastSimulatedTimetable = null;
let lastSimulatedReliability = null;

// ============================================
// Analytics Section
// ============================================

async function loadAnalytics() {
    const container = document.getElementById('analytics-container') ||
                      document.querySelector('.analytics-container');
    if (!container) return;

    if (!currentTimetable) {
        ['teacher-workload','room-utilization','schedule-density','constraint-satisfaction'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.innerHTML = '<p class="empty-state">Generate a timetable first.</p>';
        });
        return;
    }

    try {
        const resp = await fetch(`${API_BASE_URL}/analytics`);
        if (!resp.ok) throw new Error('Analytics fetch failed');
        const data = await resp.json();
        const a = data.analytics || data;
        renderTeacherWorkload(a.teacher_workload || a.teacher_hours || []);
        renderRoomUtilization(a.room_utilization || a.room_usage || []);
        renderScheduleDensity(a.schedule_density || a.density || null);
        renderConstraintSatisfaction(a.constraint_satisfaction || a.quality || null);
    } catch (err) {
        showNotification('error', `Analytics error: ${err.message}`);
    }
}

function renderTeacherWorkload(data) {
    const el = document.getElementById('teacher-workload');
    if (!el) return;
    if (!data || data.length === 0) {
        el.innerHTML = '<p class="empty-state">No workload data.</p>'; return;
    }
    const max = Math.max(...data.map(t => t.hours || t.sessions || 0), 1);
    el.innerHTML = data.map(t => {
        const name    = t.name || t.teacher_id || t.id || 'Unknown';
        const hours   = t.hours || t.sessions || 0;
        const maxload = t.max_load || t.maxload || max;
        const pct     = Math.min(100, Math.round((hours / maxload) * 100));
        const color   = pct > 90 ? 'var(--danger-color)' : pct > 70 ? 'var(--warning-color)' : 'var(--success-color)';
        return `<div class="analytics-bar-row">
            <span class="analytics-bar-label" title="${name}">${name}</span>
            <div class="analytics-bar-track">
                <div class="analytics-bar-fill" style="width:${pct}%;background:${color}"></div>
            </div>
            <span class="analytics-bar-value">${hours}/${maxload}</span>
        </div>`;
    }).join('');
}

function renderRoomUtilization(data) {
    const el = document.getElementById('room-utilization');
    if (!el) return;
    if (!data || data.length === 0) {
        el.innerHTML = '<p class="empty-state">No room data.</p>'; return;
    }
    el.innerHTML = data.map(r => {
        const name  = r.name || r.room_id || r.id || 'Unknown';
        const used  = r.used_slots || r.sessions || 0;
        const total = r.total_slots || r.capacity || 45;
        const pct   = Math.min(100, Math.round((used / total) * 100));
        const color = pct > 80 ? 'var(--danger-color)' : pct > 50 ? 'var(--warning-color)' : 'var(--success-color)';
        return `<div class="analytics-bar-row">
            <span class="analytics-bar-label" title="${name}">${name}</span>
            <div class="analytics-bar-track">
                <div class="analytics-bar-fill" style="width:${pct}%;background:${color}"></div>
            </div>
            <span class="analytics-bar-value">${pct}%</span>
        </div>`;
    }).join('');
}

function renderScheduleDensity(data) {
    const el = document.getElementById('schedule-density');
    if (!el) return;
    if (!data) {
        // Build from currentTimetable
        const assignments = currentTimetable?.assignments || [];
        const slots = {};
        (currentTimetable?.slots || currentTimetable?.timeslots || []).forEach(s => { slots[s.id] = s; });
        const byDay = {};
        assignments.forEach(a => {
            const day = (slots[a.slot_id]?.day || 'unknown').toLowerCase();
            byDay[day] = (byDay[day] || 0) + 1;
        });
        const days = ['monday','tuesday','wednesday','thursday','friday'];
        const maxSessions = Math.max(...Object.values(byDay), 1);
        el.innerHTML = `<div class="density-grid">${days.map(d => {
            const count = byDay[d] || 0;
            const pct = Math.round((count / maxSessions) * 100);
            return `<div class="density-day">
                <div class="density-bar" style="height:${pct}%;background:var(--secondary-color)"></div>
                <span class="density-label">${d.slice(0,3).toUpperCase()}</span>
                <span class="density-count">${count}</span>
            </div>`;
        }).join('')}</div>`;
        return;
    }
    el.innerHTML = `<pre class="analytics-json">${JSON.stringify(data, null, 2)}</pre>`;
}

function renderConstraintSatisfaction(data) {
    const el = document.getElementById('constraint-satisfaction');
    if (!el) return;
    if (!data) {
        el.innerHTML = '<p class="empty-state">No constraint data.</p>'; return;
    }
    const score = data.score || data.overall || data.total || 0;
    const pct   = typeof score === 'number' ? (score <= 1 ? Math.round(score * 100) : Math.round(score)) : 0;
    const color = pct >= 90 ? 'var(--success-color)' : pct >= 70 ? 'var(--warning-color)' : 'var(--danger-color)';
    const details = data.breakdown || data.details || {};
    el.innerHTML = `
        <div class="constraint-score-display">
            <span class="constraint-score-value" style="color:${color}">${pct}%</span>
            <span class="constraint-score-label">Overall Satisfaction</span>
        </div>
        ${Object.entries(details).map(([k,v]) => {
            const vPct = typeof v === 'number' ? (v <= 1 ? Math.round(v*100) : Math.round(v)) : 0;
            return `<div class="analytics-bar-row">
                <span class="analytics-bar-label">${k.replace(/_/g,' ')}</span>
                <div class="analytics-bar-track">
                    <div class="analytics-bar-fill" style="width:${vPct}%;background:var(--secondary-color)"></div>
                </div>
                <span class="analytics-bar-value">${vPct}%</span>
            </div>`;
        }).join('')}`;
}

/**
 * Wire up scenario simulation controls.
 * Called from DOMContentLoaded.
 */
function initializeScenarios() {
    // Populate teacher/room dropdowns from resourceData
    _populateScenarioDropdowns();

    const typeSelect = document.getElementById('scenario-type');
    if (!typeSelect) return;

    // Show/hide param panels when scenario type changes
    typeSelect.addEventListener('change', () => {
        document.querySelectorAll('.scenario-params').forEach(el => {
            el.style.display = 'none';
        });
        const active = document.getElementById(`params-${typeSelect.value}`);
        if (active) active.style.display = 'block';
    });

    const runBtn = document.getElementById('run-scenario-btn');
    if (runBtn) runBtn.addEventListener('click', () => simulateScenario(typeSelect.value));

    const compareBtn = document.getElementById('compare-scenarios-btn');
    if (compareBtn) compareBtn.addEventListener('click', compareWithOriginal);
}

/** Populate scenario teacher/room selects from resourceData */
function _populateScenarioDropdowns() {
    const teacherSel = document.getElementById('scenario-teacher-id');
    if (teacherSel && resourceData.teachers.length > 0) {
        const current = teacherSel.value;
        teacherSel.innerHTML = '<option value="">Select teacher…</option>' +
            resourceData.teachers.map(t => `<option value="${t.id}">${t.name}</option>`).join('');
        if (current) teacherSel.value = current;
    }
    const roomSel = document.getElementById('scenario-room-id');
    if (roomSel && resourceData.rooms.length > 0) {
        const current = roomSel.value;
        roomSel.innerHTML = '<option value="">Select room…</option>' +
            resourceData.rooms.map(r => `<option value="${r.id}">${r.name}</option>`).join('');
        if (current) roomSel.value = current;
    }
}

/**
 * simulateScenario(scenarioType)
 * Builds the params object from the active form fields and calls POST /api/simulate.
 *
 * @param {string} scenarioType - One of teacher_absence | room_maintenance | extra_class | exam_week
 */
async function simulateScenario(scenarioType) {
    const loading = document.getElementById('scenario-loading');
    const results = document.getElementById('scenario-results');
    const comparison = document.getElementById('scenario-comparison');

    if (!currentTimetable) {
        showNotification('warning', 'Generate a timetable first before running scenarios.');
        return;
    }

    loading.style.display = 'flex';
    results.style.display = 'none';
    comparison.style.display = 'none';

    try {
        const params = buildScenarioParams(scenarioType);
        const payload = { scenario: scenarioType, ...params };

        const response = await fetch(`${API_BASE_URL}/simulate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Simulation failed');
        }

        const result = await response.json();

        lastSimulatedTimetable = result.timetable;
        lastSimulatedReliability = result.reliability;

        displayScenarioComparison(result.timetable, result.reliability, result.changes || []);
        showNotification('success', 'Scenario simulation complete');

    } catch (error) {
        showNotification('error', `Simulation error: ${error.message}`);
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * buildScenarioParams(scenarioType)
 * Reads the relevant input fields and returns a params object.
 *
 * @param {string} scenarioType
 * @returns {Object}
 */
function buildScenarioParams(scenarioType) {
    switch (scenarioType) {
        case 'teacher_absence':
            return { teacher_id: document.getElementById('scenario-teacher-id').value.trim() };
        case 'room_maintenance':
            return { room_id: document.getElementById('scenario-room-id').value.trim() };
        case 'extra_class':
            return {
                class_id:   document.getElementById('scenario-class-id').value.trim(),
                subject_id: document.getElementById('scenario-subject-id').value.trim()
            };
        case 'exam_week': {
            const raw = document.getElementById('scenario-exam-slots').value.trim();
            return { exam_slots: raw.split(',').map(s => s.trim()).filter(Boolean) };
        }
        default:
            return {};
    }
}

/**
 * displayScenarioComparison(simulatedTimetable, reliability, changes)
 * Renders the simulated timetable, reliability bar, and changes list.
 *
 * @param {Object} simulatedTimetable - Timetable JSON from the API
 * @param {number} reliability        - Reliability score 0-1
 * @param {Array}  changes            - Array of change objects
 */
function displayScenarioComparison(simulatedTimetable, reliability, changes) {
    const results = document.getElementById('scenario-results');
    results.style.display = 'block';

    // Reliability bar
    const pct = Math.round((reliability || 0) * 100);
    const fill = document.getElementById('scenario-reliability-fill');
    const val  = document.getElementById('scenario-reliability-value');
    fill.style.width = `${pct}%`;
    fill.style.background = pct >= 85 ? 'var(--success-color)'
                          : pct >= 70 ? 'var(--warning-color)'
                          : 'var(--danger-color)';
    val.textContent = `${pct}%`;

    // Changes list
    const list = document.getElementById('scenario-changes-list');
    list.innerHTML = '';
    if (!changes || changes.length === 0) {
        list.innerHTML = '<li>No changes recorded.</li>';
    } else {
        changes.forEach(change => {
            const li = document.createElement('li');
            li.className = `change-${change.type || ''}`;
            li.textContent = formatChange(change);
            list.appendChild(li);
        });
    }

    // Simulated timetable grid
    const grid = document.getElementById('scenario-timetable-grid');
    renderTimetableInto(grid, simulatedTimetable, currentTimetable);
}

/**
 * compareWithOriginal()
 * Calls POST /api/compare_scenarios using the current timetable as scenario_a
 * and the last simulated timetable as scenario_b.
 */
async function compareWithOriginal() {
    if (!currentTimetable) {
        showNotification('warning', 'No original timetable available. Generate one first.');
        return;
    }
    if (!lastSimulatedTimetable) {
        showNotification('warning', 'Run a scenario first before comparing.');
        return;
    }

    const comparison = document.getElementById('scenario-comparison');
    comparison.style.display = 'none';

    try {
        // We compare the two most recent simulations by re-running the last scenario
        // against the original. For simplicity we use the stored results directly.
        const addedCount   = 0; // populated from API response below
        const removedCount = 0;

        // Render side-by-side grids from stored data
        const origGrid = document.getElementById('comparison-original-grid');
        const simGrid  = document.getElementById('comparison-simulated-grid');

        renderTimetableInto(origGrid, currentTimetable, null);
        renderTimetableInto(simGrid, lastSimulatedTimetable, currentTimetable);

        // Compute delta locally from stored reliability values
        const delta = ((lastSimulatedReliability || 0) - (currentReliability || 0));
        const deltaEl = document.getElementById('comparison-delta');
        deltaEl.textContent = (delta >= 0 ? '+' : '') + (delta * 100).toFixed(1) + '%';
        deltaEl.className = 'stat-value ' + (delta >= 0 ? 'positive' : 'negative');

        // Count diff cells
        const origAssignments = (currentTimetable && currentTimetable.assignments) || [];
        const simAssignments  = (lastSimulatedTimetable && lastSimulatedTimetable.assignments) || [];
        const added   = simAssignments.filter(a => !origAssignments.some(o => assignmentsEqual(o, a)));
        const removed = origAssignments.filter(a => !simAssignments.some(s => assignmentsEqual(s, a)));

        document.getElementById('comparison-added-count').textContent   = added.length;
        document.getElementById('comparison-removed-count').textContent = removed.length;

        comparison.style.display = 'block';

    } catch (error) {
        showNotification('error', `Comparison error: ${error.message}`);
    }
}

/**
 * renderTimetableInto(container, timetable, referenceTimetable)
 * Renders a timetable grid into the given container element.
 * If referenceTimetable is provided, cells that differ are highlighted.
 *
 * @param {HTMLElement} container
 * @param {Object}      timetable          - Timetable JSON {rooms, slots, assignments}
 * @param {Object|null} referenceTimetable - Optional reference for diff highlighting
 */
function renderTimetableInto(container, timetable, referenceTimetable) {
    container.innerHTML = '';
    if (!timetable) {
        container.innerHTML = '<p class="empty-state">No timetable data.</p>';
        return;
    }

    const rooms       = timetable.rooms       || [];
    const slots       = timetable.slots       || [];
    const assignments = timetable.assignments || [];
    const refAssignments = (referenceTimetable && referenceTimetable.assignments) || [];

    if (rooms.length === 0 || slots.length === 0) {
        container.innerHTML = '<p class="empty-state">No rooms or slots in timetable.</p>';
        return;
    }

    // Build lookup: "roomId-slotId" -> assignment
    const lookup = {};
    assignments.forEach(a => {
        lookup[`${a.room_id}-${a.slot_id}`] = a;
    });
    const refLookup = {};
    refAssignments.forEach(a => {
        refLookup[`${a.room_id}-${a.slot_id}`] = a;
    });

    // Header row
    const headerRow = document.createElement('div');
    headerRow.className = 'timetable-row timetable-header';
    headerRow.appendChild(createCell('Time / Room', 'timetable-cell timetable-header-cell'));
    rooms.forEach(room => {
        headerRow.appendChild(createCell(room.name || room.id, 'timetable-cell timetable-header-cell'));
    });
    container.appendChild(headerRow);

    // Data rows
    slots.forEach(slot => {
        const row = document.createElement('div');
        row.className = 'timetable-row';

        const timeLabel = `${slot.day || ''} P${slot.period || ''} (${slot.start_time || ''})`;
        row.appendChild(createCell(timeLabel, 'timetable-cell timetable-time-cell'));

        rooms.forEach(room => {
            const key = `${room.id}-${slot.id}`;
            const assignment = lookup[key];
            const refAssignment = refLookup[key];

            let cellClass = 'timetable-cell';
            let cellText  = '';

            if (assignment) {
                cellText = `${assignment.class_id || ''}: ${assignment.subject_id || ''} (${assignment.teacher_id || ''})`;
                cellClass += ' timetable-cell--assigned';

                // Diff highlighting
                if (referenceTimetable) {
                    if (!refAssignment) {
                        cellClass += ' diff-added';
                    } else if (!assignmentsEqual(assignment, refAssignment)) {
                        cellClass += ' diff-added';
                    }
                }
            } else {
                cellText = '';
                if (referenceTimetable && refAssignment) {
                    cellClass += ' diff-removed';
                }
            }

            row.appendChild(createCell(cellText, cellClass));
        });

        container.appendChild(row);
    });
}

/**
 * assignmentsEqual(a, b)
 * Returns true if two assignment objects represent the same scheduling decision.
 */
function assignmentsEqual(a, b) {
    return a.room_id    === b.room_id    &&
           a.slot_id    === b.slot_id    &&
           a.class_id   === b.class_id   &&
           a.subject_id === b.subject_id &&
           a.teacher_id === b.teacher_id;
}

/**
 * createCell(text, className)
 * Helper to create a div cell element.
 */
function createCell(text, className) {
    const cell = document.createElement('div');
    cell.className = className;
    cell.textContent = text;
    return cell;
}

/**
 * formatChange(change)
 * Returns a human-readable string for a change object.
 */
function formatChange(change) {
    switch (change.type) {
        case 'reassigned':
            return `Reassigned: Class ${change.class_id}, Subject ${change.subject_id}`;
        case 'unassigned':
            return `Could not reassign: Class ${change.class_id}, Subject ${change.subject_id}`;
        case 'added_session':
            return `Added session: Class ${change.class_id}, Subject ${change.subject_id}`;
        case 'failed_to_add':
            return `Failed to add: Class ${change.class_id}, Subject ${change.subject_id}`;
        case 'removed_for_exam':
            return `Removed for exam: Class ${change.class_id}, Subject ${change.subject_id} (Slot ${change.slot_id})`;
        default:
            return JSON.stringify(change);
    }
}

// ============================================
// Feature 4: Timetable Quality Scoring
// ============================================

/**
 * displayQualityScore(quality)
 * Renders the quality score panel with a circular indicator and breakdown bars.
 *
 * @param {Object} quality - { overall, hard_constraints, workload_balance,
 *                             room_utilization, schedule_compactness }
 */
function displayQualityScore(quality) {
    const panel = document.getElementById('quality-panel');
    if (!panel) return;

    panel.style.display = 'block';

    const overall = quality.overall || 0;

    // Circular SVG indicator (circumference = 2π × 50 ≈ 314)
    const circumference = 314;
    const offset = circumference - (overall / 100) * circumference;
    const circleFill = document.getElementById('quality-circle-fill');
    if (circleFill) {
        circleFill.style.strokeDashoffset = offset;
        circleFill.style.stroke = scoreColor(overall);
    }

    const overallEl = document.getElementById('quality-overall-value');
    if (overallEl) overallEl.textContent = overall;

    // Breakdown bars
    setQualityBar('hard',     quality.hard_constraints);
    setQualityBar('workload', quality.workload_balance);
    setQualityBar('room',     quality.room_utilization);
    setQualityBar('compact',  quality.schedule_compactness);
}

/**
 * setQualityBar(key, value)
 * Updates a single breakdown bar and its label.
 */
function setQualityBar(key, value) {
    const pct = value !== undefined ? value : 0;
    const bar = document.getElementById(`qbar-${key}`);
    const val = document.getElementById(`qval-${key}`);
    if (bar) {
        bar.style.width = `${pct}%`;
        bar.style.backgroundColor = scoreColor(pct);
    }
    if (val) val.textContent = `${pct}%`;
}

/**
 * scoreColor(score)
 * Returns a CSS color string based on the score value (0-100).
 */
function scoreColor(score) {
    if (score >= 75) return 'var(--success-color)';
    if (score >= 50) return 'var(--warning-color)';
    return 'var(--danger-color)';
}

/**
 * loadQualityScore()
 * Fetches GET /api/quality_score and renders the result.
 */
async function loadQualityScore() {
    try {
        const response = await fetch(`${API_BASE_URL}/quality_score`);
        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to load quality score');
        }
        const result = await response.json();
        if (result.status === 'success' && result.quality) {
            displayQualityScore(result.quality);
        }
    } catch (error) {
        console.error('Quality score error:', error);
    }
}

// Wire up the refresh button and auto-load after generation
document.addEventListener('DOMContentLoaded', () => {
    const refreshBtn = document.getElementById('refresh-quality-btn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', loadQualityScore);
    }
});

// Patch: after timetable renders, also load quality score (only when a new timetable is set)
// NOTE: quality score loading is inlined into the original renderTimetable function above


// ============================================
// Feature 5: AI Recommendation Engine
// ============================================

// Holds the recommendation currently staged for apply-after-preview
let _pendingRecommendation = null;

/**
 * initializeRecommendations()
 * Wire up the load button and preview modal controls.
 */
function initializeRecommendations() {
    const loadBtn = document.getElementById('load-recommendations-btn');
    if (loadBtn) loadBtn.addEventListener('click', loadRecommendations);

    const closeBtn = document.getElementById('rec-preview-close');
    if (closeBtn) closeBtn.addEventListener('click', closeRecPreview);

    const cancelBtn = document.getElementById('rec-preview-cancel');
    if (cancelBtn) cancelBtn.addEventListener('click', closeRecPreview);

    const confirmBtn = document.getElementById('rec-preview-confirm');
    if (confirmBtn) confirmBtn.addEventListener('click', applyPendingRecommendation);
}

/**
 * loadRecommendations()
 * Fetches GET /api/recommendations and renders the results.
 */
async function loadRecommendations() {
    const loading = document.getElementById('recommendations-loading');
    const list    = document.getElementById('recommendations-list');

    if (!loading || !list) return;
    loading.style.display = 'flex';
    list.innerHTML = '';

    try {
        const response = await fetch(`${API_BASE_URL}/recommendations`);

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to load recommendations');
        }

        const result = await response.json();
        const recs = result.recommendations || [];
        displayRecommendations(recs);

    } catch (error) {
        list.innerHTML = `<p class="empty-state" style="color:var(--danger-color)">Error: ${error.message}</p>`;
        showNotification('error', `Could not load recommendations: ${error.message}`);
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * displayRecommendations(recommendations)
 * Renders the list of recommendation cards.
 *
 * @param {Array} recommendations - Array of recommendation objects from the API.
 */
function displayRecommendations(recommendations) {
    const list = document.getElementById('recommendations-list');
    list.innerHTML = '';

    if (!recommendations || recommendations.length === 0) {
        list.innerHTML = '<p class="empty-state">No recommendations – your timetable looks great!</p>';
        return;
    }

    recommendations.forEach((rec, idx) => {
        const priority = rec.priority || 3;
        const category = (rec.category || 'general').replace(/_/g, ' ');
        const description = rec.description || '';

        const card = document.createElement('div');
        card.className = `recommendation-card priority-${priority}`;
        card.dataset.index = idx;

        const priorityLabel = priority === 1 ? 'High' : priority === 2 ? 'Medium' : 'Low';

        card.innerHTML = `
            <div class="rec-header">
                <span class="rec-priority-badge p${priority}">${priorityLabel} Priority</span>
                <span class="rec-category-badge">${category}</span>
            </div>
            <div class="rec-description">${description}</div>
            <div class="rec-actions">
                <button class="btn-rec-preview" data-index="${idx}" aria-label="Preview this recommendation">
                    Preview Change
                </button>
                <button class="btn-rec-apply" data-index="${idx}" aria-label="Apply this recommendation">
                    Apply
                </button>
            </div>
        `;

        // Wire up buttons
        card.querySelector('.btn-rec-preview').addEventListener('click', () => showRecPreview(rec, card));
        card.querySelector('.btn-rec-apply').addEventListener('click', (e) => applyRecommendation(rec, e.target));

        list.appendChild(card);
    });
}

/**
 * showRecPreview(rec, cardEl)
 * Opens the before/after preview modal for a recommendation.
 *
 * @param {Object}      rec    - The recommendation object.
 * @param {HTMLElement} cardEl - The card element (used to find the apply button).
 */
async function showRecPreview(rec, cardEl) {
    _pendingRecommendation = rec;

    const modal = document.getElementById('rec-preview-modal');
    const beforeGrid = document.getElementById('rec-preview-before');
    const afterGrid  = document.getElementById('rec-preview-after');
    const relEl      = document.getElementById('rec-preview-reliability');

    // Show current timetable as "before"
    renderTimetableInto(beforeGrid, currentTimetable, null);
    afterGrid.innerHTML = '<p class="empty-state">Applying recommendation…</p>';
    relEl.textContent = '';
    modal.classList.add('active');

    try {
        const response = await fetch(`${API_BASE_URL}/apply_recommendation`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(rec)
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Preview failed');
        }

        const result = await response.json();
        renderTimetableInto(afterGrid, result.timetable, currentTimetable);

        const relPct = result.reliability !== undefined
            ? Math.round(result.reliability * 100) + '%'
            : 'N/A';
        relEl.textContent = `Reliability after change: ${relPct}`;

        // Store the result so confirm can use it without re-calling the API
        _pendingRecommendation._previewResult = result;

    } catch (error) {
        afterGrid.innerHTML = `<p class="empty-state" style="color:var(--danger-color)">Preview error: ${error.message}</p>`;
    }
}

/**
 * closeRecPreview()
 * Closes the before/after preview modal without applying.
 */
function closeRecPreview() {
    const modal = document.getElementById('rec-preview-modal');
    modal.classList.remove('active');
    _pendingRecommendation = null;
}

/**
 * applyPendingRecommendation()
 * Confirms and applies the recommendation that was previewed.
 */
function applyPendingRecommendation() {
    if (!_pendingRecommendation) return;

    const result = _pendingRecommendation._previewResult;
    if (result && result.timetable) {
        currentTimetable  = result.timetable;
        currentReliability = result.reliability;
        renderTimetable(currentTimetable);
        updateReliabilityDisplay(currentReliability);
        showNotification('success', 'Recommendation applied – timetable updated');
    }

    closeRecPreview();
    // Reload recommendations to reflect the updated state
    loadRecommendations();
}

/**
 * applyRecommendation(rec, buttonEl)
 * Directly applies a recommendation (without preview) and refreshes the view.
 *
 * @param {Object}      rec      - The recommendation object.
 * @param {HTMLElement} buttonEl - The apply button element.
 */
async function applyRecommendation(rec, buttonEl) {
    buttonEl.disabled = true;
    buttonEl.textContent = 'Applying…';

    try {
        const response = await fetch(`${API_BASE_URL}/apply_recommendation`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(rec)
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to apply recommendation');
        }

        const result = await response.json();

        if (result.timetable) {
            currentTimetable  = result.timetable;
        }
        if (result.reliability !== undefined) {
            currentReliability = result.reliability;
        }

        showNotification('success', 'Recommendation applied – timetable updated');
        renderTimetable(currentTimetable);
        updateReliabilityDisplay(currentReliability);

        // Reload recommendations to reflect the updated state
        loadRecommendations();

    } catch (error) {
        showNotification('error', `Failed to apply: ${error.message}`);
        buttonEl.disabled = false;
        buttonEl.textContent = 'Apply';
    }
}

// ============================================
// Feature 6: Visual Heatmap
// ============================================

// Track the currently selected heatmap type
let currentHeatmapType = 'teacher';

/**
 * initializeHeatmap()
 * Wire up heatmap type selector buttons and the load button.
 * Called from DOMContentLoaded.
 */
function initializeHeatmap() {
    // Type selector buttons
    document.querySelectorAll('.heatmap-type-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.heatmap-type-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentHeatmapType = btn.dataset.type;
        });
    });

    const loadBtn = document.getElementById('load-heatmap-btn');
    if (loadBtn) {
        loadBtn.addEventListener('click', () => loadHeatmap(currentHeatmapType));
    }
}

/**
 * loadHeatmap(type)
 * Fetches GET /api/heatmap?type=<type> and renders the result.
 *
 * @param {string} type - 'teacher' | 'room' | 'timeslot'
 */
async function loadHeatmap(type) {
    const grid    = document.getElementById('heatmap-grid');
    const loading = document.getElementById('heatmap-loading');

    if (!grid || !loading) return;
    loading.style.display = 'flex';
    grid.innerHTML = '';

    try {
        const response = await fetch(`${API_BASE_URL}/heatmap?type=${encodeURIComponent(type)}`);

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to load heatmap');
        }

        const result = await response.json();

        if (result.status !== 'success' || !result.heatmap) {
            throw new Error(result.message || 'Invalid heatmap response');
        }

        renderHeatmap(result.heatmap);
        showNotification('success', `${capitalize(type)} heatmap loaded`);

    } catch (error) {
        grid.innerHTML = `<p class="empty-state" style="color:var(--danger-color)">Error: ${error.message}</p>`;
        showNotification('error', `Heatmap error: ${error.message}`);
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * renderHeatmap(heatmapData)
 * Renders heatmap cells into the heatmap grid.
 * Uses a green → yellow → red color gradient based on intensity.
 *
 * @param {Object} heatmapData - { type, cells: [{id, label, intensity}] }
 */
function renderHeatmap(heatmapData) {
    const grid = document.getElementById('heatmap-grid');
    grid.innerHTML = '';

    const cells = heatmapData.cells || [];

    if (cells.length === 0) {
        grid.innerHTML = '<p class="empty-state">No data available for this heatmap type.</p>';
        return;
    }

    cells.forEach(cell => {
        const intensity = typeof cell.intensity === 'number' ? cell.intensity : 0;
        const pct       = Math.round(intensity * 100);
        const color     = intensityToColor(intensity);
        const tooltip   = `${cell.label}: ${pct}% utilization`;

        const div = document.createElement('div');
        div.className = 'heatmap-cell';
        div.style.backgroundColor = color;
        div.setAttribute('data-tooltip', tooltip);
        div.setAttribute('aria-label', tooltip);

        div.innerHTML = `
            <span class="heatmap-cell-label">${escapeHtml(cell.label || cell.id || '')}</span>
            <span class="heatmap-cell-value">${pct}%</span>
        `;

        grid.appendChild(div);
    });
}

/**
 * intensityToColor(intensity)
 * Maps a [0.0, 1.0] intensity value to a CSS color string.
 * 0.0 = green (#27ae60), 0.5 = yellow (#f39c12), 1.0 = red (#e74c3c)
 *
 * @param {number} intensity - Value in [0.0, 1.0]
 * @returns {string} CSS rgb() color
 */
function intensityToColor(intensity) {
    const t = Math.max(0, Math.min(1, intensity));

    // Green  → Yellow (t: 0 → 0.5)
    // Yellow → Red    (t: 0.5 → 1.0)
    let r, g, b;

    if (t <= 0.5) {
        const ratio = t / 0.5;
        // Green (#27ae60) → Yellow (#f39c12)
        r = Math.round(0x27 + ratio * (0xf3 - 0x27));
        g = Math.round(0xae + ratio * (0x9c - 0xae));
        b = Math.round(0x60 + ratio * (0x12 - 0x60));
    } else {
        const ratio = (t - 0.5) / 0.5;
        // Yellow (#f39c12) → Red (#e74c3c)
        r = Math.round(0xf3 + ratio * (0xe7 - 0xf3));
        g = Math.round(0x9c + ratio * (0x4c - 0x9c));
        b = Math.round(0x12 + ratio * (0x3c - 0x12));
    }

    return `rgb(${r},${g},${b})`;
}

/**
 * escapeHtml(str)
 * Escapes HTML special characters to prevent XSS.
 */
function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

/**
 * capitalize(str)
 * Capitalizes the first letter of a string.
 */
function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// initializeHeatmap is called from main DOMContentLoaded

// ============================================
// Feature 7: AI Search Visualization
// ============================================

/**
 * loadSearchStatistics()
 * Fetches GET /api/search_stats and renders the results.
 */
async function loadSearchStatistics() {
    const loading  = document.getElementById('search-stats-loading');
    const cards    = document.getElementById('search-stats-cards');
    const chart    = document.getElementById('search-chart-container');
    const emptyMsg = document.getElementById('search-stats-empty');

    if (!loading || !cards || !chart) return;
    loading.style.display = 'flex';
    cards.style.display   = 'none';
    chart.style.display   = 'none';

    try {
        const response = await fetch(`${API_BASE_URL}/search_stats`);

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to load search statistics');
        }

        const result = await response.json();

        if (result.status !== 'success' || !result.stats) {
            throw new Error(result.message || 'Invalid response from server');
        }

        displaySearchStatistics(result.stats);
        if (emptyMsg) emptyMsg.style.display = 'none';

    } catch (error) {
        if (emptyMsg) {
            emptyMsg.textContent = `Error: ${error.message}`;
            emptyMsg.style.display = 'block';
        }
        showNotification('error', `Search stats error: ${error.message}`);
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * displaySearchStatistics(stats)
 * Populates the summary cards and triggers the bar chart.
 *
 * @param {Object} stats - { nodes_explored, backtracks, heuristic_applications,
 *                           domain_prunings, assignments_made, constraint_checks }
 */
function displaySearchStatistics(stats) {
    const cards = document.getElementById('search-stats-cards');
    const chart = document.getElementById('search-chart-container');

    // Populate summary cards
    const mapping = {
        'stat-nodes':       stats.nodes_explored        || 0,
        'stat-backtracks':  stats.backtracks            || 0,
        'stat-heuristics':  stats.heuristic_applications|| 0,
        'stat-prunings':    stats.domain_prunings       || 0,
        'stat-assignments': stats.assignments_made      || 0,
        'stat-checks':      stats.constraint_checks     || 0
    };

    Object.entries(mapping).forEach(([id, value]) => {
        const el = document.getElementById(id);
        if (el) el.textContent = value.toLocaleString();
    });

    cards.style.display = 'grid';

    // Draw bar chart
    visualizeSearchTree(stats);
    chart.style.display = 'block';
}

/**
 * visualizeSearchTree(stats)
 * Draws a bar chart of the search statistics using the Canvas API.
 *
 * @param {Object} stats - Statistics object from the API.
 */
function visualizeSearchTree(stats) {
    const canvas = document.getElementById('search-stats-canvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');

    // Data to visualise
    const metrics = [
        { label: 'Nodes',       value: stats.nodes_explored         || 0, color: '#3498db' },
        { label: 'Backtracks',  value: stats.backtracks             || 0, color: '#e74c3c' },
        { label: 'Heuristics',  value: stats.heuristic_applications || 0, color: '#9b59b6' },
        { label: 'Prunings',    value: stats.domain_prunings        || 0, color: '#f39c12' },
        { label: 'Assignments', value: stats.assignments_made       || 0, color: '#27ae60' },
        { label: 'Checks',      value: stats.constraint_checks      || 0, color: '#1abc9c' }
    ];

    const W = canvas.width;
    const H = canvas.height;
    const paddingLeft   = 60;
    const paddingRight  = 20;
    const paddingTop    = 20;
    const paddingBottom = 50;
    const chartW = W - paddingLeft - paddingRight;
    const chartH = H - paddingTop  - paddingBottom;

    ctx.clearRect(0, 0, W, H);

    const maxVal = Math.max(...metrics.map(m => m.value), 1);
    const barWidth  = Math.floor(chartW / metrics.length);
    const barGap    = Math.max(4, Math.floor(barWidth * 0.15));
    const barActual = barWidth - barGap;

    // Draw Y-axis gridlines and labels
    ctx.strokeStyle = '#e0e0e0';
    ctx.fillStyle   = '#666';
    ctx.font        = '11px sans-serif';
    ctx.textAlign   = 'right';
    const ySteps = 5;
    for (let i = 0; i <= ySteps; i++) {
        const yVal = Math.round((maxVal / ySteps) * i);
        const y    = paddingTop + chartH - (chartH * i / ySteps);
        ctx.beginPath();
        ctx.moveTo(paddingLeft, y);
        ctx.lineTo(paddingLeft + chartW, y);
        ctx.stroke();
        ctx.fillText(yVal.toLocaleString(), paddingLeft - 6, y + 4);
    }

    // Draw bars
    metrics.forEach((metric, idx) => {
        const barH = maxVal > 0 ? (metric.value / maxVal) * chartH : 0;
        const x    = paddingLeft + idx * barWidth + Math.floor(barGap / 2);
        const y    = paddingTop  + chartH - barH;

        // Bar fill
        ctx.fillStyle = metric.color;
        ctx.fillRect(x, y, barActual, barH);

        // Value label above bar
        ctx.fillStyle   = '#333';
        ctx.font        = '11px sans-serif';
        ctx.textAlign   = 'center';
        if (metric.value > 0) {
            ctx.fillText(metric.value.toLocaleString(), x + barActual / 2, y - 4);
        }

        // X-axis label
        ctx.fillStyle = '#555';
        ctx.font      = '12px sans-serif';
        ctx.fillText(metric.label, x + barActual / 2, paddingTop + chartH + 20);
    });

    // Y-axis line
    ctx.strokeStyle = '#aaa';
    ctx.lineWidth   = 1;
    ctx.beginPath();
    ctx.moveTo(paddingLeft, paddingTop);
    ctx.lineTo(paddingLeft, paddingTop + chartH);
    ctx.stroke();
}

// Wire up the load button and auto-load after generation
const _loadSearchStatsBtnInit = () => {
    const btn = document.getElementById('load-search-stats-btn');
    if (btn) btn.addEventListener('click', loadSearchStatistics);
};
document.addEventListener('DOMContentLoaded', _loadSearchStatsBtnInit);

// Auto-load search statistics after timetable generation completes
// NOTE: stats loading is inlined into the original generateTimetable function above

// ============================================
// Feature 8: Multiple Timetable Generation
// ============================================

// Holds the full list of ranked solutions returned by the last call
let _multiSolutions = [];
// Index of the solution currently shown in the preview modal
let _previewSolutionIndex = null;

/**
 * initializeMultiSolutions()
 * Wire up the generate button and preview modal controls.
 * Called from DOMContentLoaded.
 */
function initializeMultiSolutions() {
    const btn = document.getElementById('generate-multiple-btn');
    if (btn) btn.addEventListener('click', generateMultipleTimetables);

    const closeBtn  = document.getElementById('solution-preview-close');
    const cancelBtn = document.getElementById('solution-preview-cancel');
    const selectBtn = document.getElementById('solution-preview-select');

    if (closeBtn)  closeBtn.addEventListener('click',  closeSolutionPreview);
    if (cancelBtn) cancelBtn.addEventListener('click',  closeSolutionPreview);
    if (selectBtn) selectBtn.addEventListener('click',  selectPreviewedTimetable);
}

/**
 * generateMultipleTimetables()
 * Reads the count input, calls POST /api/generate_multiple, and renders results.
 */
async function generateMultipleTimetables() {
    if (!currentTimetable) {
        showNotification('error', 'Generate a timetable first before generating multiple solutions');
        return;
    }

    const countInput = document.getElementById('solution-count');
    const count = Math.max(2, Math.min(10, parseInt(countInput.value, 10) || 3));

    const loading = document.getElementById('multi-solutions-loading');
    const list    = document.getElementById('multi-solutions-list');

    loading.style.display = 'flex';
    list.innerHTML = '';

    try {
        const response = await fetch(`${API_BASE_URL}/generate_multiple`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ count })
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to generate multiple timetables');
        }

        const result = await response.json();
        _multiSolutions = result.solutions || [];
        displayMultipleSolutions(_multiSolutions);
        showNotification('success', `Generated ${_multiSolutions.length} timetable solutions`);

    } catch (error) {
        list.innerHTML = `<p class="empty-state" style="color:var(--danger-color)">Error: ${error.message}</p>`;
        showNotification('error', `Multiple generation failed: ${error.message}`);
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * displayMultipleSolutions(solutions)
 * Renders a ranked card for each solution.
 *
 * @param {Array} solutions - Array of { timetable, quality_score, reliability, combined_score }
 */
function displayMultipleSolutions(solutions) {
    const list = document.getElementById('multi-solutions-list');
    list.innerHTML = '';

    if (!solutions || solutions.length === 0) {
        list.innerHTML = '<p class="empty-state">No solutions generated. Ensure resources are loaded and try again.</p>';
        return;
    }

    solutions.forEach((sol, idx) => {
        const quality     = sol.quality_score  !== undefined ? sol.quality_score  : 0;
        const reliability = sol.reliability    !== undefined ? (sol.reliability * 100).toFixed(1) : '0.0';
        const combined    = sol.combined_score !== undefined ? (sol.combined_score * 100).toFixed(1) : '0.0';

        const card = document.createElement('div');
        card.className = 'solution-card';
        card.dataset.index = idx;

        card.innerHTML = `
            <div class="solution-rank">#${idx + 1}</div>
            <div class="solution-badges">
                <span class="badge badge--quality" title="Quality score out of 100">
                    ⭐ Quality: ${quality}/100
                </span>
                <span class="badge badge--reliability" title="Reliability probability">
                    🛡 Reliability: ${reliability}%
                </span>
                <span class="badge badge--combined" title="Combined ranking score">
                    🏆 Score: ${combined}%
                </span>
            </div>
            <div class="solution-actions">
                <button class="btn btn-secondary btn-sm" data-action="preview" data-index="${idx}"
                        aria-label="Preview timetable ${idx + 1}">
                    Preview
                </button>
                <button class="btn btn-primary btn-sm" data-action="select" data-index="${idx}"
                        aria-label="Use timetable ${idx + 1}">
                    Use This
                </button>
            </div>
        `;

        // Wire up buttons
        card.querySelector('[data-action="preview"]').addEventListener('click', () => previewTimetable(idx));
        card.querySelector('[data-action="select"]').addEventListener('click', () => selectTimetable(idx));

        list.appendChild(card);
    });
}

/**
 * previewTimetable(index)
 * Opens the preview modal showing the timetable grid for the given solution index.
 *
 * @param {number} index - Index into _multiSolutions
 */
function previewTimetable(index) {
    const sol = _multiSolutions[index];
    if (!sol) return;

    _previewSolutionIndex = index;

    const modal      = document.getElementById('solution-preview-modal');
    const titleEl    = document.getElementById('solution-preview-title');
    const badgesEl   = document.getElementById('solution-preview-badges');
    const gridEl     = document.getElementById('solution-preview-grid');

    titleEl.textContent = `Timetable #${index + 1}`;

    const quality     = sol.quality_score  !== undefined ? sol.quality_score  : 0;
    const reliability = sol.reliability    !== undefined ? (sol.reliability * 100).toFixed(1) : '0.0';
    const combined    = sol.combined_score !== undefined ? (sol.combined_score * 100).toFixed(1) : '0.0';

    badgesEl.innerHTML = `
        <span class="badge badge--quality">⭐ Quality: ${quality}/100</span>
        <span class="badge badge--reliability">🛡 Reliability: ${reliability}%</span>
        <span class="badge badge--combined">🏆 Score: ${combined}%</span>
    `;

    renderTimetableInto(gridEl, sol.timetable, null);
    modal.classList.add('active');
}

/**
 * closeSolutionPreview()
 * Closes the solution preview modal.
 */
function closeSolutionPreview() {
    const modal = document.getElementById('solution-preview-modal');
    modal.classList.remove('active');
    _previewSolutionIndex = null;
}

/**
 * selectTimetable(index)
 * Sets the chosen solution as the active timetable and switches to the
 * Visualize section.
 *
 * @param {number} index - Index into _multiSolutions
 */
function selectTimetable(index) {
    const sol = _multiSolutions[index];
    if (!sol || !sol.timetable) {
        showNotification('error', 'Solution data not available');
        return;
    }

    currentTimetable   = sol.timetable;
    currentReliability = sol.reliability;

    // Highlight the selected card
    document.querySelectorAll('.solution-card').forEach((card, i) => {
        card.classList.toggle('solution-card--selected', i === index);
    });

    // Switch to visualize section and render
    switchSection('visualize');
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.section === 'visualize');
    });
    renderTimetable(currentTimetable);
    updateReliabilityDisplay(currentReliability);
    checkAndHighlightConflicts();

    showNotification('success', `Timetable #${index + 1} selected and loaded`);
    closeSolutionPreview();
}

/**
 * selectPreviewedTimetable()
 * Applies the currently previewed solution (called from modal confirm button).
 */
function selectPreviewedTimetable() {
    if (_previewSolutionIndex !== null) {
        selectTimetable(_previewSolutionIndex);
    }
}

// initializeMultiSolutions is called from main DOMContentLoaded

// ============================================
// Feature 9: Constraint Importance Sliders
// ============================================

// Default weights matching the Prolog backend defaults
const DEFAULT_WEIGHTS = {
    workload_balance:   0.8,
    avoid_late_theory:  0.7,
    minimize_gaps:      0.6,
    teacher_preference: 0.5,
    room_optimization:  0.5,
    student_compact:    0.6
};

// Current in-memory weights (kept in sync with the server)
let currentWeights = { ...DEFAULT_WEIGHTS };

/**
 * initializeConstraintSliders()
 * Wire up all slider inputs, buttons, and load current weights from the server.
 * Called from DOMContentLoaded.
 */
function initializeConstraintSliders() {
    // Wire up each slider to update its value display and track fill
    document.querySelectorAll('.constraint-slider').forEach(slider => {
        updateSliderTrack(slider);
        slider.addEventListener('input', () => {
            updateSliderTrack(slider);
            const constraint = slider.dataset.constraint;
            const pct = parseInt(slider.value, 10);
            const display = document.getElementById(`val-${constraint}`);
            if (display) display.textContent = `${pct}%`;
        });
    });

    // Apply weights button
    const applyBtn = document.getElementById('apply-weights-btn');
    if (applyBtn) applyBtn.addEventListener('click', applyWeights);

    // Regenerate with weights button
    const regenBtn = document.getElementById('regenerate-with-weights-btn');
    if (regenBtn) regenBtn.addEventListener('click', regenerateWithWeights);

    // Reset to defaults button
    const resetBtn = document.getElementById('reset-weights-btn');
    if (resetBtn) resetBtn.addEventListener('click', resetWeights);

    // Load current weights from server on section activation
    loadConstraintWeights();
}

/**
 * updateSliderTrack(slider)
 * Updates the CSS custom property that drives the filled portion of the track.
 *
 * @param {HTMLInputElement} slider
 */
function updateSliderTrack(slider) {
    const pct = ((slider.value - slider.min) / (slider.max - slider.min)) * 100;
    slider.style.setProperty('--slider-pct', `${pct}%`);
}

/**
 * loadConstraintWeights()
 * Fetches GET /api/constraint_weights and syncs the sliders.
 */
async function loadConstraintWeights() {
    try {
        const response = await fetch(`${API_BASE_URL}/constraint_weights`);
        if (!response.ok) return; // Silently fail on load - server may not be running yet

        const result = await response.json();
        if (result.status === 'success' && result.weights) {
            currentWeights = { ...DEFAULT_WEIGHTS, ...result.weights };
            syncSlidersToWeights(currentWeights);
            renderWeightsSummary(currentWeights);
        }
    } catch (_) {
        // Server not available yet - use defaults
    }
}

/**
 * syncSlidersToWeights(weights)
 * Sets each slider's value to match the provided weights object.
 *
 * @param {Object} weights - { constraintName: floatValue, ... }
 */
function syncSlidersToWeights(weights) {
    Object.entries(weights).forEach(([name, value]) => {
        const slider = document.getElementById(`slider-${name}`);
        const display = document.getElementById(`val-${name}`);
        if (slider) {
            const pct = Math.round(value * 100);
            slider.value = pct;
            updateSliderTrack(slider);
            if (display) display.textContent = `${pct}%`;
        }
    });
}

/**
 * readWeightsFromSliders()
 * Reads the current slider positions and returns a weights object.
 *
 * @returns {Object} { constraintName: floatValue, ... }
 */
function readWeightsFromSliders() {
    const weights = {};
    document.querySelectorAll('.constraint-slider').forEach(slider => {
        const name = slider.dataset.constraint;
        weights[name] = parseInt(slider.value, 10) / 100;
    });
    return weights;
}

/**
 * applyWeights()
 * Reads slider values and POSTs them to POST /api/set_weights.
 */
async function applyWeights() {
    const weights = readWeightsFromSliders();
    const statusEl = document.getElementById('constraints-status');

    try {
        const response = await fetch(`${API_BASE_URL}/set_weights`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(weights)
        });

        const result = await response.json();

        if (result.status === 'success') {
            currentWeights = weights;
            renderWeightsSummary(currentWeights);
            showConstraintsStatus('Weights applied successfully.', 'success');
            showNotification('success', 'Constraint weights updated');
        } else {
            throw new Error(result.message || 'Failed to apply weights');
        }
    } catch (error) {
        showConstraintsStatus(`Error: ${error.message}`, 'error');
        showNotification('error', `Could not apply weights: ${error.message}`);
    }
}

/**
 * regenerateWithWeights()
 * Applies current slider weights then calls POST /api/generate_with_weights
 * to produce a new timetable.
 */
async function regenerateWithWeights() {
    const weights = readWeightsFromSliders();
    const loading = document.getElementById('constraints-loading');

    loading.style.display = 'flex';
    showConstraintsStatus('', 'info');

    try {
        const response = await fetch(`${API_BASE_URL}/generate_with_weights`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ weights })
        });

        const result = await response.json();

        if (result.status === 'success') {
            currentTimetable   = result.timetable;
            currentReliability = result.reliability;
            currentWeights     = weights;

            renderWeightsSummary(currentWeights);
            showConstraintsStatus('Timetable regenerated with custom weights.', 'success');
            showNotification('success', 'Timetable regenerated with custom weights');

            // Switch to visualize section
            switchSection('visualize');
            document.querySelectorAll('.nav-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.section === 'visualize');
            });
            renderTimetable(currentTimetable);
            updateReliabilityDisplay(currentReliability);
            checkAndHighlightConflicts();
        } else {
            throw new Error(result.message || 'Generation failed');
        }
    } catch (error) {
        showConstraintsStatus(`Error: ${error.message}`, 'error');
        showNotification('error', `Weighted generation failed: ${error.message}`);
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * resetWeights()
 * Resets all sliders to default values and syncs with the server.
 */
async function resetWeights() {
    syncSlidersToWeights(DEFAULT_WEIGHTS);

    try {
        const response = await fetch(`${API_BASE_URL}/set_weights`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(DEFAULT_WEIGHTS)
        });

        const result = await response.json();
        if (result.status === 'success') {
            currentWeights = { ...DEFAULT_WEIGHTS };
            renderWeightsSummary(currentWeights);
            showConstraintsStatus('Weights reset to defaults.', 'success');
            showNotification('info', 'Constraint weights reset to defaults');
        }
    } catch (error) {
        // Reset locally even if server call fails
        currentWeights = { ...DEFAULT_WEIGHTS };
        renderWeightsSummary(currentWeights);
        showConstraintsStatus('Weights reset locally (server unavailable).', 'success');
    }
}

/**
 * renderWeightsSummary(weights)
 * Renders the summary card showing each constraint name, bar, and value.
 *
 * @param {Object} weights
 */
function renderWeightsSummary(weights) {
    const container = document.getElementById('weights-summary');
    if (!container) return;

    const labels = {
        workload_balance:   'Workload Balance',
        avoid_late_theory:  'Avoid Late Theory',
        minimize_gaps:      'Minimize Gaps',
        teacher_preference: 'Teacher Preference',
        room_optimization:  'Room Optimisation',
        student_compact:    'Student Compact'
    };

    container.innerHTML = '';
    Object.entries(weights).forEach(([name, value]) => {
        const pct = Math.round(value * 100);
        const label = labels[name] || name.replace(/_/g, ' ');
        const barColor = pct >= 70 ? 'var(--success-color)'
                       : pct >= 40 ? 'var(--warning-color)'
                       : 'var(--danger-color)';

        const row = document.createElement('div');
        row.className = 'weight-summary-row';
        row.innerHTML = `
            <span class="weight-summary-name">${label}</span>
            <div class="weight-summary-bar-wrap">
                <div class="weight-summary-bar" style="width:${pct}%; background:${barColor};"></div>
            </div>
            <span class="weight-summary-value">${pct}%</span>
        `;
        container.appendChild(row);
    });
}

/**
 * showConstraintsStatus(message, type)
 * Shows a status message in the constraints section.
 *
 * @param {string} message
 * @param {string} type - 'success' | 'error' | 'info'
 */
function showConstraintsStatus(message, type) {
    const el = document.getElementById('constraints-status');
    if (!el) return;
    if (!message) {
        el.style.display = 'none';
        return;
    }
    el.className = `constraints-status ${type}`;
    el.textContent = message;
    el.style.display = 'block';
}

// initializeConstraintSliders is called from main DOMContentLoaded

// ============================================
// Feature 10: Real-Time Validation
// ============================================

/**
 * Debounce helper – delays fn execution until after `wait` ms of inactivity.
 */
function debounce(fn, wait = 400) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), wait);
    };
}

/**
 * validateFieldRealtime(formId, resourceType)
 * Calls POST /api/validate_input with the current form values and updates
 * inline validation messages for each field.
 *
 * @param {string} formId       - The HTML id of the form element
 * @param {string} resourceType - teacher | subject | room | timeslot | class
 */
async function validateFieldRealtime(formId, resourceType) {
    const form = document.getElementById(formId);
    if (!form) return;

    const data = collectFormData(formId, resourceType);
    if (!data) return;

    try {
        const response = await fetch(`${API_BASE_URL}/validate_input`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (!response.ok) return;

        const result = await response.json();
        applyValidationUI(form, result);
    } catch (_) {
        // Network unavailable – clear validation state silently
    }
}

/**
 * collectFormData(formId, resourceType)
 * Reads the current form values into a plain object ready for the API.
 */
function collectFormData(formId, resourceType) {
    const form = document.getElementById(formId);
    if (!form) return null;

    const fd = new FormData(form);
    const data = { type: resourceType };

    switch (resourceType) {
        case 'teacher':
            data.name = fd.get('name') || '';
            data.qualified_subjects = (fd.get('subjects') || '').split(',').map(s => s.trim()).filter(Boolean);
            data.max_load = parseFloat(fd.get('maxload')) || 0;
            data.availability = (fd.get('availability') || '').split(',').map(s => s.trim()).filter(Boolean);
            break;
        case 'subject':
            data.name = fd.get('name') || '';
            data.weekly_hours = parseFloat(fd.get('hours')) || 0;
            data.type = fd.get('type') || '';
            data.duration = parseFloat(fd.get('duration')) || 0;
            break;
        case 'room':
            data.name = fd.get('name') || '';
            data.capacity = parseFloat(fd.get('capacity')) || 0;
            data.type = fd.get('type') || '';
            break;
        case 'timeslot':
            data.day = fd.get('day') || '';
            data.period = parseFloat(fd.get('period')) || 0;
            data.start_time = fd.get('start') || '';
            data.duration = parseFloat(fd.get('duration')) || 0;
            break;
        case 'class':
            data.name = fd.get('name') || '';
            data.subjects = (fd.get('subjects') || '').split(',').map(s => s.trim()).filter(Boolean);
            break;
        default:
            return null;
    }

    return data;
}

/**
 * applyValidationUI(form, result)
 * Updates the form's inline validation messages and submit button state
 * based on the API response.
 */
function applyValidationUI(form, result) {
    const isValid = result.valid === true;
    const errors = result.errors || [];
    const conflicts = result.conflicts || [];
    const allIssues = [...errors, ...conflicts];

    // Update each field's validation message container
    form.querySelectorAll('.validation-msg').forEach(el => {
        el.textContent = '';
        el.className = 'validation-msg';
        const group = el.closest('.form-group');
        if (group) {
            group.classList.remove('valid', 'invalid');
        }
    });

    if (isValid && allIssues.length === 0) {
        // Mark all fields as valid
        form.querySelectorAll('.form-group').forEach(group => {
            const input = group.querySelector('input, select');
            if (input && input.value) {
                group.classList.add('valid');
                const msg = group.querySelector('.validation-msg');
                if (msg) {
                    msg.className = 'validation-msg valid';
                    msg.innerHTML = '<span class="validation-icon">✓</span> Looks good';
                }
            }
        });
    } else {
        // Show first error as a general message on the first field with a msg container
        const firstMsg = form.querySelector('.validation-msg');
        if (firstMsg && allIssues.length > 0) {
            firstMsg.className = 'validation-msg invalid';
            firstMsg.innerHTML = `<span class="validation-icon">✗</span> ${allIssues[0]}`;
            const group = firstMsg.closest('.form-group');
            if (group) group.classList.add('invalid');
        }
    }

    // Enable / disable submit button
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
        submitBtn.disabled = !isValid || allIssues.length > 0;
    }
}

/**
 * addValidationMsgContainers(formId)
 * Injects a .validation-msg <span> after the first input/select in each
 * form-group if one doesn't already exist.
 */
function addValidationMsgContainers(formId) {
    const form = document.getElementById(formId);
    if (!form) return;

    form.querySelectorAll('.form-group').forEach(group => {
        if (!group.querySelector('.validation-msg')) {
            const span = document.createElement('span');
            span.className = 'validation-msg';
            group.appendChild(span);
        }
    });
}

/**
 * initializeRealtimeValidation()
 * Attaches debounced input/change listeners to all resource forms.
 */
function initializeRealtimeValidation() {
    const forms = [
        { id: 'teacher-form',  type: 'teacher' },
        { id: 'subject-form',  type: 'subject' },
        { id: 'room-form',     type: 'room' },
        { id: 'timeslot-form', type: 'timeslot' },
        { id: 'class-form',    type: 'class' }
    ];

    forms.forEach(({ id, type }) => {
        const form = document.getElementById(id);
        if (!form) return;

        // Inject validation message containers
        addValidationMsgContainers(id);

        // Debounced validator
        const debouncedValidate = debounce(() => validateFieldRealtime(id, type), 450);

        // Listen on every input and select inside the form
        form.querySelectorAll('input, select').forEach(field => {
            field.addEventListener('input', debouncedValidate);
            field.addEventListener('change', debouncedValidate);
        });

        // Re-enable submit on reset so the user can try again
        form.addEventListener('reset', () => {
            form.querySelectorAll('.form-group').forEach(g => g.classList.remove('valid', 'invalid'));
            form.querySelectorAll('.validation-msg').forEach(m => {
                m.textContent = '';
                m.className = 'validation-msg';
            });
            const submitBtn = form.querySelector('button[type="submit"]');
            if (submitBtn) submitBtn.disabled = false;
        });
    });
}

// initializeRealtimeValidation is called from main DOMContentLoaded

// ============================================
// Genetic Algorithm Optimization (Feature 11 - Task 28A.3)
// ============================================

// Store CSP solution metrics for comparison
let cspSolutionMetrics = null;

/**
 * Initialize GA section event listeners.
 */
function initializeGA() {
    const gaBtn = document.getElementById('ga-optimize-btn');
    if (gaBtn) {
        gaBtn.addEventListener('click', runGAOptimization);
    }
}

/**
 * Run the Genetic Algorithm optimization via the API.
 */
async function runGAOptimization() {
    if (!currentTimetable) {
        showNotification('error', 'Generate a timetable first before running GA optimization');
        return;
    }

    const populationSize = parseInt(document.getElementById('ga-population-size').value) || 20;
    const generations    = parseInt(document.getElementById('ga-generations').value)    || 50;
    const mutationRate   = parseFloat(document.getElementById('ga-mutation-rate').value)  || 0.1;
    const crossoverRate  = parseFloat(document.getElementById('ga-crossover-rate').value) || 0.8;

    // Show loading
    document.getElementById('ga-loading').style.display = 'flex';
    document.getElementById('ga-progress').style.display = 'none';
    document.getElementById('ga-chart-container').style.display = 'none';
    document.getElementById('ga-comparison').style.display = 'none';
    document.getElementById('ga-result').style.display = 'none';
    document.getElementById('ga-optimize-btn').disabled = true;

    try {
        const response = await fetch(`${API_BASE_URL}/optimize_ga`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                population_size: populationSize,
                generations:     generations,
                mutation_rate:   mutationRate,
                crossover_rate:  crossoverRate
            })
        });

        const data = await response.json();

        if (data.status === 'success') {
            displayGAResults(data);
            showNotification('GA optimization complete!', 'success');
        } else {
            showGAError(data.message || 'GA optimization failed');
        }
    } catch (err) {
        showGAError('Network error: ' + err.message);
    } finally {
        document.getElementById('ga-loading').style.display = 'none';
        document.getElementById('ga-optimize-btn').disabled = false;
    }
}

/**
 * Display GA results: progress stats, fitness chart, and comparison table.
 * @param {Object} data - API response data
 */
function displayGAResults(data) {
    // Show progress stats
    const progressEl = document.getElementById('ga-progress');
    progressEl.style.display = 'flex';
    document.getElementById('ga-best-fitness').textContent =
        (data.fitness !== undefined ? (data.fitness * 100).toFixed(1) + '%' : '--');
    document.getElementById('ga-reliability').textContent =
        (data.reliability !== undefined ? (data.reliability * 100).toFixed(1) + '%' : '--');

    // Draw fitness history chart
    if (data.fitness_history && data.fitness_history.length > 0) {
        drawFitnessChart(data.fitness_history);
        document.getElementById('ga-chart-container').style.display = 'block';
    }

    // Show comparison with CSP solution (if available)
    buildComparisonTable(data);

    // Show result message
    const resultEl = document.getElementById('ga-result');
    resultEl.style.display = 'block';
    resultEl.className = 'result-box success';
    resultEl.innerHTML = `
        <strong>✓ GA Optimization Complete</strong><br>
        Best fitness: ${data.fitness !== undefined ? (data.fitness * 100).toFixed(2) + '%' : 'N/A'}<br>
        Reliability: ${data.reliability !== undefined ? (data.reliability * 100).toFixed(2) + '%' : 'N/A'}<br>
        Generations run: ${data.fitness_history ? data.fitness_history.length : 'N/A'}
    `;

    // Store GA metrics for future comparisons
    window.gaMetrics = {
        fitness:     data.fitness,
        reliability: data.reliability,
        generations: data.fitness_history ? data.fitness_history.length : 0
    };
}

/**
 * Draw the fitness history as a line chart on the canvas.
 * @param {number[]} history - Array of best fitness values per generation
 */
function drawFitnessChart(history) {
    const canvas = document.getElementById('ga-fitness-chart');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    const W = canvas.width;
    const H = canvas.height;
    const PAD = { top: 20, right: 20, bottom: 40, left: 55 };
    const chartW = W - PAD.left - PAD.right;
    const chartH = H - PAD.top  - PAD.bottom;

    ctx.clearRect(0, 0, W, H);

    // Background
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, W, H);

    const minVal = Math.min(...history);
    const maxVal = Math.max(...history);
    const range  = maxVal - minVal || 0.01;

    // Grid lines
    ctx.strokeStyle = '#e0e0e0';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 5; i++) {
        const y = PAD.top + chartH - (i / 5) * chartH;
        ctx.beginPath();
        ctx.moveTo(PAD.left, y);
        ctx.lineTo(PAD.left + chartW, y);
        ctx.stroke();
        // Y-axis labels
        ctx.fillStyle = '#666';
        ctx.font = '11px sans-serif';
        ctx.textAlign = 'right';
        const label = ((minVal + (i / 5) * range) * 100).toFixed(1) + '%';
        ctx.fillText(label, PAD.left - 6, y + 4);
    }

    // Axes
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(PAD.left, PAD.top);
    ctx.lineTo(PAD.left, PAD.top + chartH);
    ctx.lineTo(PAD.left + chartW, PAD.top + chartH);
    ctx.stroke();

    // Axis labels
    ctx.fillStyle = '#333';
    ctx.font = '12px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('Generation', PAD.left + chartW / 2, H - 5);
    ctx.save();
    ctx.translate(14, PAD.top + chartH / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText('Best Fitness', 0, 0);
    ctx.restore();

    // Line
    ctx.strokeStyle = '#3498db';
    ctx.lineWidth = 2;
    ctx.beginPath();
    history.forEach((val, i) => {
        const x = PAD.left + (i / (history.length - 1 || 1)) * chartW;
        const y = PAD.top  + chartH - ((val - minVal) / range) * chartH;
        if (i === 0) ctx.moveTo(x, y);
        else         ctx.lineTo(x, y);
    });
    ctx.stroke();

    // Dots at start and end
    [[0, history[0]], [history.length - 1, history[history.length - 1]]].forEach(([i, val]) => {
        const x = PAD.left + (i / (history.length - 1 || 1)) * chartW;
        const y = PAD.top  + chartH - ((val - minVal) / range) * chartH;
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, Math.PI * 2);
        ctx.fillStyle = '#2980b9';
        ctx.fill();
    });
}

/**
 * Build the CSP vs GA comparison table.
 * @param {Object} gaData - GA result data
 */
function buildComparisonTable(gaData) {
    const tbody = document.getElementById('ga-comparison-body');
    if (!tbody) return;

    // Try to get CSP metrics from stored state
    const cspFitness     = (window.currentReliability !== undefined) ? window.currentReliability : null;
    const gaFitness      = gaData.fitness;
    const gaReliability  = gaData.reliability;

    const rows = [
        {
            metric: 'Fitness Score',
            csp:    cspFitness !== null ? (cspFitness * 100).toFixed(1) + '%' : 'N/A',
            ga:     gaFitness  !== undefined ? (gaFitness * 100).toFixed(1) + '%' : 'N/A',
            better: (gaFitness !== undefined && cspFitness !== null) ? (gaFitness >= cspFitness ? 'ga' : 'csp') : null
        },
        {
            metric: 'Reliability',
            csp:    cspFitness !== null ? (cspFitness * 100).toFixed(1) + '%' : 'N/A',
            ga:     gaReliability !== undefined ? (gaReliability * 100).toFixed(1) + '%' : 'N/A',
            better: null
        },
        {
            metric: 'Algorithm',
            csp:    'CSP Backtracking',
            ga:     'Genetic Algorithm',
            better: null
        }
    ];

    tbody.innerHTML = rows.map(row => `
        <tr>
            <td>${row.metric}</td>
            <td class="${row.better === 'csp' ? 'better' : (row.better === 'ga' ? 'worse' : '')}">${row.csp}</td>
            <td class="${row.better === 'ga'  ? 'better' : (row.better === 'csp' ? 'worse' : '')}">${row.ga}</td>
        </tr>
    `).join('');

    document.getElementById('ga-comparison').style.display = 'block';
}

/**
 * Show an error message in the GA result box.
 * @param {string} message
 */
function showGAError(message) {
    const resultEl = document.getElementById('ga-result');
    resultEl.style.display = 'block';
    resultEl.className = 'result-box error';
    resultEl.textContent = '✗ ' + message;
    showNotification(message, 'error');
}

// Register GA initialization
// initializeGA is called from main DOMContentLoaded


// ============================================================
// Feature 12: Interactive Drag-and-Drop Editing
// ============================================================

// State for the drag-and-drop editor
const dragEditState = {
    dragSource: null,   // { roomId, slotId }
    timetable: null     // cached timetable data
};

function initializeDragEdit() {
    const loadBtn = document.getElementById('drag-edit-load-btn');
    if (loadBtn) loadBtn.addEventListener('click', loadTimetableForEditing);

    const warningClose = document.getElementById('drag-warning-close');
    if (warningClose) warningClose.addEventListener('click', closeDragWarningModal);

    const warningOk = document.getElementById('drag-warning-ok');
    if (warningOk) warningOk.addEventListener('click', closeDragWarningModal);
}

/** Load the current timetable from the API and render the editable grid. */
async function loadTimetableForEditing() {
    const loading = document.getElementById('drag-edit-loading');
    loading.style.display = 'flex';
    setDragEditStatus('', '');

    try {
        const res = await fetch(`${API_BASE_URL}/timetable`);
        const data = await res.json();
        if (data.status === 'success' && data.timetable) {
            dragEditState.timetable = data.timetable;
            renderDragEditGrid(data.timetable);
            setDragEditStatus('Timetable loaded. Drag cells to rearrange.', 'info');
        } else {
            setDragEditStatus(data.message || 'No timetable available. Generate one first.', 'error');
        }
    } catch (err) {
        setDragEditStatus('Network error: ' + err.message, 'error');
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * Render the editable timetable grid.
 * @param {Object} timetable - timetable JSON from the API
 */
function renderDragEditGrid(timetable) {
    const grid = document.getElementById('drag-edit-grid');
    if (!grid) return;

    const assignments = timetable.assignments || [];
    if (!assignments.length) {
        grid.innerHTML = '<p class="empty-state">Timetable has no assignments to display.</p>';
        return;
    }

    // Collect unique rooms and slots
    const rooms = [...new Set(assignments.map(a => a.room_id))].sort();
    const slots = [...new Set(assignments.map(a => a.slot_id))].sort();

    const cols = rooms.length + 1;
    grid.style.gridTemplateColumns = `80px repeat(${rooms.length}, minmax(100px, 1fr))`;
    grid.innerHTML = '';

    // Header row: empty corner + room headers
    appendCell(grid, '', 'de-header-cell');
    rooms.forEach(r => appendCell(grid, r, 'de-header-cell'));

    // Data rows: one per slot
    slots.forEach(slotId => {
        appendCell(grid, slotId, 'de-header-cell');
        rooms.forEach(roomId => {
            const asgn = assignments.find(a => a.room_id === roomId && a.slot_id === slotId);
            const cell = document.createElement('div');
            cell.className = 'de-cell ' + (asgn ? 'assigned' : 'empty');
            cell.dataset.roomId = roomId;
            cell.dataset.slotId = slotId;

            if (asgn) {
                cell.draggable = true;
                cell.innerHTML = `
                    <div class="de-cell-subject">${asgn.subject_id || ''}</div>
                    <div class="de-cell-teacher">${asgn.teacher_id || ''}</div>`;
                cell.addEventListener('dragstart', onDragStart);
            }

            cell.addEventListener('dragover',  onDragOver);
            cell.addEventListener('dragleave', onDragLeave);
            cell.addEventListener('drop',      onDrop);
            grid.appendChild(cell);
        });
    });
}

function appendCell(parent, text, className) {
    const el = document.createElement('div');
    el.className = className;
    el.textContent = text;
    parent.appendChild(el);
}

// ---- Drag event handlers ----

function onDragStart(e) {
    const cell = e.currentTarget;
    dragEditState.dragSource = {
        roomId: cell.dataset.roomId,
        slotId: cell.dataset.slotId
    };
    cell.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', JSON.stringify(dragEditState.dragSource));
}

async function onDragOver(e) {
    e.preventDefault();
    const cell = e.currentTarget;
    if (!dragEditState.dragSource) return;

    const src = dragEditState.dragSource;
    if (cell.dataset.roomId === src.roomId && cell.dataset.slotId === src.slotId) return;

    // Real-time validation
    try {
        const res = await fetch(`${API_BASE_URL}/validate_move`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                from_room: src.roomId,
                from_slot: src.slotId,
                to_room:   cell.dataset.roomId,
                to_slot:   cell.dataset.slotId
            })
        });
        const data = await res.json();
        cell.classList.remove('drag-over-valid', 'drag-over-invalid');
        cell.classList.add(data.valid ? 'drag-over-valid' : 'drag-over-invalid');
        e.dataTransfer.dropEffect = data.valid ? 'move' : 'none';
    } catch (_) {
        cell.classList.add('drag-over-invalid');
    }
}

function onDragLeave(e) {
    e.currentTarget.classList.remove('drag-over-valid', 'drag-over-invalid');
}

async function onDrop(e) {
    e.preventDefault();
    const targetCell = e.currentTarget;
    targetCell.classList.remove('drag-over-valid', 'drag-over-invalid');

    // Clear dragging style from source
    document.querySelectorAll('.de-cell.dragging').forEach(c => c.classList.remove('dragging'));

    const src = dragEditState.dragSource;
    if (!src) return;
    if (targetCell.dataset.roomId === src.roomId && targetCell.dataset.slotId === src.slotId) return;

    const toRoom = targetCell.dataset.roomId;
    const toSlot = targetCell.dataset.slotId;

    // Validate first
    try {
        const valRes = await fetch(`${API_BASE_URL}/validate_move`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                from_room: src.roomId, from_slot: src.slotId,
                to_room: toRoom, to_slot: toSlot
            })
        });
        const valData = await valRes.json();

        if (!valData.valid) {
            // Show warning modal with violations and alternatives
            await showDragWarningModal(valData.warnings || [], src);
            return;
        }

        // Apply the move
        const applyRes = await fetch(`${API_BASE_URL}/apply_move`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                from_room: src.roomId, from_slot: src.slotId,
                to_room: toRoom, to_slot: toSlot
            })
        });
        const applyData = await applyRes.json();

        if (applyData.status === 'success') {
            dragEditState.timetable = applyData.timetable;
            renderDragEditGrid(applyData.timetable);
            const effectCount = (applyData.effects || []).length;
            const msg = effectCount > 0
                ? `Move applied. ${effectCount} cascading effect(s) detected and resolved.`
                : 'Move applied successfully.';
            setDragEditStatus(msg, 'success');
            showNotification(msg, 'success');
        } else {
            setDragEditStatus(applyData.message || 'Move failed.', 'error');
        }
    } catch (err) {
        setDragEditStatus('Network error: ' + err.message, 'error');
    } finally {
        dragEditState.dragSource = null;
    }
}

// ---- Warning modal helpers ----

/**
 * Show the constraint-violation warning modal with optional alternatives.
 * @param {string[]} warnings
 * @param {{ roomId: string, slotId: string }} src
 */
async function showDragWarningModal(warnings, src) {
    const modal   = document.getElementById('drag-warning-modal');
    const msgEl   = document.getElementById('drag-warning-message');
    const altPanel = document.getElementById('drag-alternatives-panel');
    const altList  = document.getElementById('drag-alternatives-list');

    msgEl.textContent = warnings.length
        ? warnings.join(' | ')
        : 'This move violates one or more constraints.';

    // Fetch alternatives
    altList.innerHTML = '';
    altPanel.style.display = 'none';
    try {
        const res = await fetch(`${API_BASE_URL}/suggest_alternatives`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ from_room: src.roomId, from_slot: src.slotId })
        });
        const data = await res.json();
        const alts = data.alternatives || [];
        if (alts.length) {
            altPanel.style.display = 'block';
            alts.slice(0, 8).forEach(alt => {
                const li = document.createElement('li');
                li.textContent = `Room ${alt.room_id}  ·  Slot ${alt.slot_id}`;
                li.addEventListener('click', () => applyAlternative(src, alt));
                altList.appendChild(li);
            });
        }
    } catch (_) { /* silently ignore */ }

    modal.style.display = 'flex';
}

function closeDragWarningModal() {
    const modal = document.getElementById('drag-warning-modal');
    if (modal) modal.style.display = 'none';
}

/**
 * Apply a suggested alternative slot chosen from the warning modal.
 */
async function applyAlternative(src, alt) {
    closeDragWarningModal();
    try {
        const res = await fetch(`${API_BASE_URL}/apply_move`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                from_room: src.roomId, from_slot: src.slotId,
                to_room: alt.room_id, to_slot: alt.slot_id
            })
        });
        const data = await res.json();
        if (data.status === 'success') {
            dragEditState.timetable = data.timetable;
            renderDragEditGrid(data.timetable);
            setDragEditStatus('Alternative applied successfully.', 'success');
            showNotification('Alternative slot applied.', 'success');
        } else {
            setDragEditStatus(data.message || 'Could not apply alternative.', 'error');
        }
    } catch (err) {
        setDragEditStatus('Network error: ' + err.message, 'error');
    }
}

/** Set the status bar text and style in the drag-edit section. */
function setDragEditStatus(message, type) {
    const el = document.getElementById('drag-edit-status');
    if (!el) return;
    if (!message) { el.style.display = 'none'; return; }
    el.textContent = message;
    el.className = `drag-edit-status ${type}`;
    el.style.display = 'block';
}

// Register drag-edit initialization
// initializeDragEdit is called from main DOMContentLoaded

// ============================================================
// Historical Learning System (Feature 13 - Task 28C.3)
// ============================================================

/**
 * Load and display learning statistics from the backend.
 */
async function loadLearningStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/learning_stats`);
        const data = await response.json();
        if (data.status === 'success') {
            displayLearningStats(data.learning);
        } else {
            showNotification('Failed to load learning statistics: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (err) {
        showNotification('Error loading learning statistics: ' + err.message, 'error');
    }
}

/**
 * Display learning statistics in the dashboard.
 * @param {Object} stats - Learning statistics from the API.
 */
function displayLearningStats(stats) {
    // Update summary counters
    const setEl = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.textContent = val;
    };

    setEl('timetables-analysed', stats.timetables_analysed || 0);
    setEl('patterns-discovered', stats.patterns_discovered || 0);

    const preferredSlots = stats.preferred_slots || [];
    const successfulAssignments = stats.successful_assignments || [];

    setEl('preferred-slots-count', preferredSlots.length);
    setEl('successful-assignments-count', successfulAssignments.length);

    // Render preferred slots table
    const slotsContainer = document.getElementById('preferred-slots-container');
    if (slotsContainer) {
        if (preferredSlots.length === 0) {
            slotsContainer.innerHTML = '<p class="empty-state">No preferred slot patterns learned yet. Generate and save some timetables first.</p>';
        } else {
            const rows = preferredSlots
                .sort((a, b) => b.count - a.count)
                .map(p => `
                    <tr>
                        <td>${p.teacher_id}</td>
                        <td>${p.slot_id}</td>
                        <td><span class="pattern-count-badge">${p.count}</span></td>
                    </tr>`)
                .join('');
            slotsContainer.innerHTML = `
                <table class="pattern-table">
                    <thead>
                        <tr><th>Teacher ID</th><th>Slot ID</th><th>Frequency</th></tr>
                    </thead>
                    <tbody>${rows}</tbody>
                </table>`;
        }
    }

    // Render successful assignments table
    const assignContainer = document.getElementById('successful-assignments-container');
    if (assignContainer) {
        if (successfulAssignments.length === 0) {
            assignContainer.innerHTML = '<p class="empty-state">No successful assignment patterns learned yet.</p>';
        } else {
            const rows = successfulAssignments
                .sort((a, b) => b.count - a.count)
                .map(p => `
                    <tr>
                        <td>${p.teacher_id}</td>
                        <td>${p.subject_id}</td>
                        <td><span class="pattern-count-badge">${p.count}</span></td>
                    </tr>`)
                .join('');
            assignContainer.innerHTML = `
                <table class="pattern-table">
                    <thead>
                        <tr><th>Teacher ID</th><th>Subject ID</th><th>Frequency</th></tr>
                    </thead>
                    <tbody>${rows}</tbody>
                </table>`;
        }
    }
}

/**
 * Store the current timetable in the learning history.
 */
async function applyLearning() {
    try {
        const response = await fetch(`${API_BASE_URL}/apply_learning`, { method: 'POST' });
        const data = await response.json();
        if (data.status === 'success') {
            showNotification('Timetable stored in learning history.', 'success');
            if (data.learning) displayLearningStats(data.learning);
        } else {
            showNotification('Failed to apply learning: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (err) {
        showNotification('Error applying learning: ' + err.message, 'error');
    }
}

/**
 * Clear all learning history and patterns.
 */
async function clearLearningHistory() {
    if (!confirm('Clear all learning history and patterns? This cannot be undone.')) return;
    try {
        const response = await fetch(`${API_BASE_URL}/clear_history`, { method: 'POST' });
        const data = await response.json();
        if (data.status === 'success') {
            showNotification('Learning history cleared.', 'success');
            // Reset display
            displayLearningStats({
                timetables_analysed: 0,
                patterns_discovered: 0,
                preferred_slots: [],
                successful_assignments: []
            });
        } else {
            showNotification('Failed to clear history: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (err) {
        showNotification('Error clearing history: ' + err.message, 'error');
    }
}

// Auto-load learning stats when the learning section becomes active
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.nav-btn[data-section="learning"]').forEach(btn => {
        btn.addEventListener('click', loadLearningStats);
    });
});


// ============================================================
// Pattern Discovery (Feature 14 - Task 28D.3)
// ============================================================

/** State for accepted patterns */
let acceptedPatterns = [];

/**
 * discoverPatterns()
 * POST /api/discover_patterns – analyse the current timetable and display
 * the discovered patterns with confidence bars and accept/reject buttons.
 */
async function discoverPatterns() {
    if (!currentTimetable) {
        showNotification('Generate a timetable first before discovering patterns.', 'warning');
        return;
    }

    const btn = document.getElementById('discover-patterns-btn');
    const loading = document.getElementById('pattern-loading');
    btn.disabled = true;
    loading.style.display = 'inline';

    try {
        const response = await fetch(`${API_BASE_URL}/discover_patterns`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        const data = await response.json();

        if (data.status === 'success') {
            displayDiscoveredPatterns(data.patterns || []);
            showNotification(`Discovered ${data.count} pattern(s).`, 'success');
        } else {
            showNotification('Pattern discovery failed: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (err) {
        showNotification('Error discovering patterns: ' + err.message, 'error');
    } finally {
        btn.disabled = false;
        loading.style.display = 'none';
    }
}

/**
 * displayDiscoveredPatterns(patterns)
 * Render the list of discovered patterns and update the summary stats.
 */
function displayDiscoveredPatterns(patterns) {
    const statsEl = document.getElementById('pattern-stats');
    const listCard = document.getElementById('pattern-list-card');
    const container = document.getElementById('pattern-list-container');
    const chartCard = document.getElementById('pattern-chart-card');

    statsEl.style.display = 'grid';
    listCard.style.display = 'block';
    chartCard.style.display = 'block';

    // Update summary counts
    const counts = { temporal: 0, resource: 0, teacher: 0 };
    patterns.forEach(p => { if (counts[p.type] !== undefined) counts[p.type]++; });
    document.getElementById('pattern-count-temporal').textContent = counts.temporal;
    document.getElementById('pattern-count-resource').textContent = counts.resource;
    document.getElementById('pattern-count-teacher').textContent = counts.teacher;

    if (patterns.length === 0) {
        container.innerHTML = '<p class="empty-state">No significant patterns found in the current timetable.</p>';
        chartCard.style.display = 'none';
        return;
    }

    container.innerHTML = patterns.map((p, idx) => buildPatternCard(p, idx)).join('');
    renderPatternChart(patterns);
}

/**
 * buildPatternCard(pattern, index)
 * Returns the HTML string for a single pattern card.
 */
function buildPatternCard(pattern, idx) {
    const pct = pattern.confidence_pct || Math.round((pattern.confidence || 0) * 100);
    const fillClass = pct >= 80 ? 'high' : pct >= 60 ? 'medium' : 'low';
    const typeLabel = pattern.type || 'unknown';

    return `
    <div class="pattern-item" id="pattern-item-${idx}">
        <div class="pattern-item-header">
            <span class="pattern-type-badge ${typeLabel}">${typeLabel}</span>
            <strong>Confidence: ${pct}%</strong>
        </div>
        <p class="pattern-description">${escapeHtml(pattern.description || '')}</p>
        <div class="confidence-bar-wrapper">
            <div class="confidence-bar-track">
                <div class="confidence-bar-fill ${fillClass}" style="width:${pct}%"></div>
            </div>
            <span class="confidence-label">${pct}%</span>
        </div>
        <div class="pattern-actions">
            <button class="btn-accept" onclick="acceptPattern(${idx}, ${JSON.stringify(pattern).replace(/"/g, '&quot;')})">
                ✓ Accept
            </button>
            <button class="btn-reject" onclick="rejectPattern(${idx})">
                ✗ Reject
            </button>
        </div>
    </div>`;
}

/**
 * acceptPattern(index, pattern)
 * POST /api/apply_pattern – store the accepted pattern as a soft constraint.
 */
async function acceptPattern(idx, pattern) {
    try {
        const response = await fetch(`${API_BASE_URL}/apply_pattern`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                constraint: pattern.suggested_constraint,
                description: pattern.description
            })
        });
        const data = await response.json();

        if (data.status === 'success') {
            // Mark card as accepted
            const card = document.getElementById(`pattern-item-${idx}`);
            if (card) {
                card.classList.add('accepted');
                card.querySelector('.pattern-actions').innerHTML =
                    '<span style="color:#43a047;font-weight:600;">✓ Accepted as soft constraint</span>';
            }
            acceptedPatterns.push(pattern);
            updateAcceptedPatternsPanel();
            // Update accepted count
            document.getElementById('pattern-count-accepted').textContent = acceptedPatterns.length;
            showNotification('Pattern accepted as soft constraint.', 'success');
        } else {
            showNotification('Failed to accept pattern: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (err) {
        showNotification('Error accepting pattern: ' + err.message, 'error');
    }
}

/**
 * rejectPattern(index)
 * Visually marks the pattern card as rejected (no API call needed).
 */
function rejectPattern(idx) {
    const card = document.getElementById(`pattern-item-${idx}`);
    if (card) {
        card.classList.add('rejected');
    }
}

/**
 * updateAcceptedPatternsPanel()
 * Refresh the "Accepted Soft Constraints" panel.
 */
function updateAcceptedPatternsPanel() {
    const card = document.getElementById('accepted-patterns-card');
    const container = document.getElementById('accepted-patterns-container');
    card.style.display = 'block';

    if (acceptedPatterns.length === 0) {
        container.innerHTML = '<p class="empty-state">No constraints accepted yet.</p>';
        return;
    }

    container.innerHTML = acceptedPatterns.map(p => `
        <div class="accepted-constraint-item">
            <span class="accepted-constraint-icon">✓</span>
            <div>
                <strong>${escapeHtml(p.description || '')}</strong><br>
                <small style="color:#888;">${escapeHtml(p.suggested_constraint || '')}</small>
            </div>
        </div>`).join('');
}

/**
 * renderPatternChart(patterns)
 * Draw a simple horizontal bar chart on the canvas showing confidence per pattern.
 */
function renderPatternChart(patterns) {
    const canvas = document.getElementById('pattern-chart');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    const barHeight = 28;
    const gap = 10;
    const labelWidth = 220;
    const chartWidth = canvas.width - labelWidth - 20;
    const totalHeight = patterns.length * (barHeight + gap) + 30;
    canvas.height = Math.max(totalHeight, 80);

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const typeColors = { temporal: '#1565c0', resource: '#2e7d32', teacher: '#e65100' };

    patterns.forEach((p, i) => {
        const y = 20 + i * (barHeight + gap);
        const pct = p.confidence_pct || Math.round((p.confidence || 0) * 100);
        const barW = Math.round((pct / 100) * chartWidth);
        const color = typeColors[p.type] || '#555';

        // Label
        ctx.fillStyle = '#333';
        ctx.font = '12px sans-serif';
        const label = (p.description || '').substring(0, 35) + ((p.description || '').length > 35 ? '…' : '');
        ctx.fillText(label, 0, y + barHeight / 2 + 4);

        // Bar background
        ctx.fillStyle = '#e0e0e0';
        ctx.fillRect(labelWidth, y, chartWidth, barHeight);

        // Bar fill
        ctx.fillStyle = color;
        ctx.fillRect(labelWidth, y, barW, barHeight);

        // Percentage label
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 11px sans-serif';
        if (barW > 30) {
            ctx.fillText(`${pct}%`, labelWidth + barW - 28, y + barHeight / 2 + 4);
        } else {
            ctx.fillStyle = '#333';
            ctx.fillText(`${pct}%`, labelWidth + barW + 4, y + barHeight / 2 + 4);
        }
    });
}

/** Simple HTML escaping helper - uses existing escapeHtml if available */

// ============================================================================
// What-If Optimization Dashboard (Feature 15 - Task 28E.3)
// ============================================================================

/** Internal state for the what-if dashboard */
let whatIfScenarios = [];       // list of scenario param objects
let whatIfLastResults = null;   // last analysis response from the API

/**
 * updateWhatIfParams
 * Render the appropriate parameter input fields for the selected scenario type.
 */
function updateWhatIfParams() {
    const type = document.getElementById('whatif-scenario-type').value;
    const container = document.getElementById('whatif-params-container');
    container.innerHTML = '';

    if (type === 'teacher_absence') {
        container.innerHTML = `
            <div class="form-group whatif-param-field">
                <label for="whatif-teacher-id">Teacher ID</label>
                <input type="text" id="whatif-teacher-id" class="form-control"
                       placeholder="e.g., t1" />
            </div>`;
    } else if (type === 'room_maintenance') {
        container.innerHTML = `
            <div class="form-group whatif-param-field">
                <label for="whatif-room-id">Room ID</label>
                <input type="text" id="whatif-room-id" class="form-control"
                       placeholder="e.g., r2" />
            </div>`;
    } else if (type === 'extra_class') {
        container.innerHTML = `
            <div class="form-group whatif-param-field">
                <label for="whatif-class-id">Class ID</label>
                <input type="text" id="whatif-class-id" class="form-control"
                       placeholder="e.g., cs1" />
            </div>
            <div class="form-group whatif-param-field">
                <label for="whatif-subject-id">Subject ID</label>
                <input type="text" id="whatif-subject-id" class="form-control"
                       placeholder="e.g., math" />
            </div>`;
    } else if (type === 'exam_week') {
        container.innerHTML = `
            <div class="form-group whatif-param-field">
                <label for="whatif-exam-slots">Exam Slot IDs (comma-separated)</label>
                <input type="text" id="whatif-exam-slots" class="form-control"
                       placeholder="e.g., slot1,slot2,slot3" />
            </div>`;
    }
    // baseline has no extra params
}

/**
 * addWhatIfScenario
 * Read the current form values and push a scenario descriptor onto the queue.
 */
function addWhatIfScenario() {
    const type = document.getElementById('whatif-scenario-type').value;
    const params = { scenario: type };

    if (type === 'teacher_absence') {
        const tid = (document.getElementById('whatif-teacher-id') || {}).value || '';
        if (!tid.trim()) { showNotification('Please enter a Teacher ID', 'warning'); return; }
        params.teacher_id = tid.trim();
    } else if (type === 'room_maintenance') {
        const rid = (document.getElementById('whatif-room-id') || {}).value || '';
        if (!rid.trim()) { showNotification('Please enter a Room ID', 'warning'); return; }
        params.room_id = rid.trim();
    } else if (type === 'extra_class') {
        const cid = (document.getElementById('whatif-class-id') || {}).value || '';
        const sid = (document.getElementById('whatif-subject-id') || {}).value || '';
        if (!cid.trim() || !sid.trim()) {
            showNotification('Please enter both Class ID and Subject ID', 'warning');
            return;
        }
        params.class_id   = cid.trim();
        params.subject_id = sid.trim();
    } else if (type === 'exam_week') {
        const slots = (document.getElementById('whatif-exam-slots') || {}).value || '';
        if (!slots.trim()) { showNotification('Please enter exam slot IDs', 'warning'); return; }
        params.exam_slots = slots.split(',').map(s => s.trim()).filter(Boolean);
    }

    whatIfScenarios.push(params);
    renderWhatIfQueue();
    showNotification(`Scenario "${buildScenarioLabel(params)}" added`, 'success');
}

/**
 * buildScenarioLabel
 * Return a human-readable label for a scenario params object.
 */
function buildScenarioLabel(params) {
    const labels = {
        baseline:         'Baseline',
        teacher_absence:  `Teacher Absence (${params.teacher_id || '?'})`,
        room_maintenance: `Room Maintenance (${params.room_id || '?'})`,
        extra_class:      `Extra Class (${params.class_id || '?'})`,
        exam_week:        'Exam Week'
    };
    return labels[params.scenario] || params.scenario;
}

/**
 * renderWhatIfQueue
 * Refresh the scenario queue display.
 */
function renderWhatIfQueue() {
    const queueDiv  = document.getElementById('whatif-scenario-queue');
    const queueList = document.getElementById('whatif-queue-list');
    const countSpan = document.getElementById('whatif-queue-count');
    const analyzeBtn = document.getElementById('whatif-analyze-btn');

    countSpan.textContent = whatIfScenarios.length;
    queueList.innerHTML = '';

    whatIfScenarios.forEach((params, idx) => {
        const li = document.createElement('li');
        li.className = 'whatif-queue-item';
        li.innerHTML = `
            <span>${buildScenarioLabel(params)}</span>
            <button class="remove-scenario-btn" title="Remove" onclick="removeWhatIfScenario(${idx})">&#x2715;</button>`;
        queueList.appendChild(li);
    });

    queueDiv.style.display  = whatIfScenarios.length > 0 ? 'block' : 'none';
    analyzeBtn.disabled     = whatIfScenarios.length < 1;
}

/**
 * removeWhatIfScenario
 * Remove a scenario from the queue by index.
 */
function removeWhatIfScenario(index) {
    whatIfScenarios.splice(index, 1);
    renderWhatIfQueue();
}

/**
 * clearWhatIfScenarios
 * Clear all queued scenarios and hide results.
 */
function clearWhatIfScenarios() {
    whatIfScenarios = [];
    whatIfLastResults = null;
    renderWhatIfQueue();
    document.getElementById('whatif-results').style.display = 'none';
}

/**
 * runWhatIfAnalysis
 * Send the scenario list to POST /api/analyze_scenarios and display results.
 */
async function runWhatIfAnalysis() {
    if (whatIfScenarios.length === 0) {
        showNotification('Add at least one scenario before analyzing', 'warning');
        return;
    }

    const loadingEl  = document.getElementById('whatif-loading');
    const analyzeBtn = document.getElementById('whatif-analyze-btn');
    const resultsDiv = document.getElementById('whatif-results');

    loadingEl.style.display  = 'inline';
    analyzeBtn.disabled      = true;
    resultsDiv.style.display = 'none';

    try {
        const response = await fetch(`${API_BASE_URL}/analyze_scenarios`, {
            method:  'POST',
            headers: { 'Content-Type': 'application/json' },
            body:    JSON.stringify({ scenarios: whatIfScenarios })
        });
        const data = await response.json();

        if (data.status === 'success') {
            whatIfLastResults = data;
            displayWhatIfResults(data);
            showNotification('Scenario analysis complete', 'success');
        } else {
            showNotification('Analysis failed: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (err) {
        showNotification('Network error: ' + err.message, 'error');
    } finally {
        loadingEl.style.display = 'none';
        analyzeBtn.disabled     = false;
    }
}

/**
 * displayWhatIfResults
 * Render the comparison table, recommendation banner, chart, and metrics grid.
 */
function displayWhatIfResults(data) {
    const resultsDiv = document.getElementById('whatif-results');
    resultsDiv.style.display = 'block';

    const ranked         = data.ranked         || [];
    const matrix         = data.comparison_matrix || [];
    const recommendation = data.recommendation  || {};

    // Determine recommended index for highlighting
    const recIndex = recommendation.recommended_index;

    // 1. Recommendation banner
    displayWhatIfRecommendation(recommendation);

    // 2. Comparison table (use ranked order)
    renderWhatIfTable(ranked, recIndex);

    // 3. Bar chart
    renderWhatIfChart();

    // 4. Detailed metrics grid
    renderWhatIfMetricsGrid(data.results || []);
}

/**
 * displayWhatIfRecommendation
 * Populate the AI recommendation banner.
 */
function displayWhatIfRecommendation(rec) {
    document.getElementById('whatif-recommendation-name').textContent =
        rec.recommended_name ? `Recommended: ${rec.recommended_name}` : 'No recommendation available';
    document.getElementById('whatif-recommendation-reason').textContent =
        rec.reason || '';

    const tradeOffsDiv = document.getElementById('whatif-trade-offs');
    if (rec.trade_offs && rec.trade_offs.length > 0) {
        tradeOffsDiv.innerHTML = '<strong>Trade-offs:</strong><ul>' +
            rec.trade_offs.map(t => `<li>${escapeHtml(t)}</li>`).join('') +
            '</ul>';
    } else {
        tradeOffsDiv.innerHTML = '';
    }
}

/**
 * renderWhatIfTable
 * Build the comparison table from ranked results.
 */
function renderWhatIfTable(ranked, recIndex) {
    const tbody = document.getElementById('whatif-table-body');
    tbody.innerHTML = '';

    ranked.forEach(row => {
        const tr = document.createElement('tr');
        if (row.index === recIndex) tr.classList.add('recommended');

        const qualityBadge     = scoreBadge(row.metrics ? row.metrics.quality : 0);
        const reliabilityPct   = row.reliability_pct !== undefined
            ? row.reliability_pct
            : Math.round((row.reliability || 0) * 100);
        const reliabilityBadge = scoreBadge(reliabilityPct);
        const resourcePct      = row.resource_usage_pct !== undefined
            ? row.resource_usage_pct
            : Math.round((row.metrics ? (row.metrics.resource_usage || 0) : 0) * 100);
        const combinedPct      = Math.round((row.combined_score || 0) * 100);
        const combinedBadge    = scoreBadge(combinedPct);

        tr.innerHTML = `
            <td>${escapeHtml(row.name || row.scenario || '')}</td>
            <td>${qualityBadge}</td>
            <td>${reliabilityBadge}</td>
            <td>${resourcePct}%</td>
            <td>${row.changes_count !== undefined ? row.changes_count : '—'}</td>
            <td>${combinedBadge}</td>`;
        tbody.appendChild(tr);
    });

    if (ranked.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:#999;">No results</td></tr>';
    }
}

/**
 * scoreBadge
 * Return an HTML badge element for a 0-100 score.
 */
function scoreBadge(score) {
    const cls = score >= 70 ? 'high' : score >= 40 ? 'medium' : 'low';
    return `<span class="whatif-score-badge whatif-score-badge--${cls}">${score}</span>`;
}

/**
 * renderWhatIfChart
 * Draw a bar chart on the canvas for the selected metric.
 */
function renderWhatIfChart() {
    if (!whatIfLastResults) return;

    const canvas = document.getElementById('whatif-chart');
    if (!canvas) return;
    const ctx    = canvas.getContext('2d');
    const metric = document.getElementById('whatif-chart-metric').value;
    const ranked = whatIfLastResults.ranked || [];

    // Resolve canvas pixel dimensions
    const W = canvas.offsetWidth  || 700;
    const H = canvas.offsetHeight || 260;
    canvas.width  = W;
    canvas.height = H;

    ctx.clearRect(0, 0, W, H);

    if (ranked.length === 0) {
        ctx.fillStyle = '#999';
        ctx.font = '14px sans-serif';
        ctx.fillText('No data', W / 2 - 30, H / 2);
        return;
    }

    // Extract values
    const labels = ranked.map(r => r.name || r.scenario || '');
    const values = ranked.map(r => {
        if (metric === 'quality')           return r.metrics ? (r.metrics.quality || 0) : 0;
        if (metric === 'reliability_pct')   return r.reliability_pct !== undefined
            ? r.reliability_pct : Math.round((r.reliability || 0) * 100);
        if (metric === 'resource_usage_pct') return r.resource_usage_pct !== undefined
            ? r.resource_usage_pct : Math.round((r.metrics ? (r.metrics.resource_usage || 0) : 0) * 100);
        if (metric === 'changes_count')     return r.changes_count || 0;
        return 0;
    });

    const maxVal   = Math.max(...values, 1);
    const padding  = { top: 20, right: 20, bottom: 50, left: 50 };
    const chartW   = W - padding.left - padding.right;
    const chartH   = H - padding.top  - padding.bottom;
    const barW     = Math.max(20, (chartW / ranked.length) * 0.6);
    const gap      = (chartW / ranked.length) * 0.4;
    const recIndex = whatIfLastResults.recommendation
        ? whatIfLastResults.recommendation.recommended_index : -1;

    // Axes
    ctx.strokeStyle = '#ccc';
    ctx.lineWidth   = 1;
    ctx.beginPath();
    ctx.moveTo(padding.left, padding.top);
    ctx.lineTo(padding.left, padding.top + chartH);
    ctx.lineTo(padding.left + chartW, padding.top + chartH);
    ctx.stroke();

    // Bars
    ranked.forEach((r, i) => {
        const x      = padding.left + i * (barW + gap) + gap / 2;
        const barH   = (values[i] / maxVal) * chartH;
        const y      = padding.top + chartH - barH;
        const isRec  = r.index === recIndex;

        ctx.fillStyle = isRec ? '#1565c0' : '#42a5f5';
        ctx.fillRect(x, y, barW, barH);

        // Value label on top of bar
        ctx.fillStyle = '#333';
        ctx.font      = '11px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(values[i], x + barW / 2, y - 4);

        // X-axis label (truncated)
        const label = labels[i].length > 14 ? labels[i].slice(0, 12) + '…' : labels[i];
        ctx.fillStyle = isRec ? '#1565c0' : '#555';
        ctx.font      = isRec ? 'bold 10px sans-serif' : '10px sans-serif';
        ctx.fillText(label, x + barW / 2, padding.top + chartH + 16);
    });

    // Y-axis label
    ctx.save();
    ctx.translate(12, padding.top + chartH / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillStyle = '#555';
    ctx.font      = '11px sans-serif';
    ctx.textAlign = 'center';
    const metricLabels = {
        quality:            'Quality (0-100)',
        reliability_pct:    'Reliability (%)',
        resource_usage_pct: 'Resource Usage (%)',
        changes_count:      'Changes'
    };
    ctx.fillText(metricLabels[metric] || metric, 0, 0);
    ctx.restore();
}

/**
 * renderWhatIfMetricsGrid
 * Build a card per scenario showing all sub-metrics.
 */
function renderWhatIfMetricsGrid(results) {
    const grid = document.getElementById('whatif-metrics-grid');
    grid.innerHTML = '';

    const recIndex = whatIfLastResults && whatIfLastResults.recommendation
        ? whatIfLastResults.recommendation.recommended_index : -1;

    results.forEach(r => {
        const metrics = r.metrics || {};
        const isRec   = r.index === recIndex;
        const card    = document.createElement('div');
        card.className = 'whatif-metric-card';
        if (isRec) card.style.borderColor = '#1565c0';

        const rows = [
            ['Quality Score',        `${metrics.quality || 0} / 100`],
            ['Reliability',          `${Math.round((r.reliability || 0) * 100)}%`],
            ['Hard Constraints',     `${metrics.hard_constraints || 0} / 100`],
            ['Workload Balance',     `${metrics.workload_balance || 0} / 100`],
            ['Room Utilization',     `${metrics.room_utilization || 0} / 100`],
            ['Schedule Compactness', `${metrics.schedule_compactness || 0} / 100`],
            ['Resource Usage',       `${Math.round((metrics.resource_usage || 0) * 100)}%`],
            ['Changes',              r.changes_count !== undefined ? r.changes_count : '—']
        ];

        card.innerHTML = `
            <h4>${isRec ? '&#x2605; ' : ''}${escapeHtml(r.name || r.scenario || '')}</h4>
            ${rows.map(([label, val]) => `
                <div class="whatif-metric-row">
                    <span class="whatif-metric-label">${label}</span>
                    <span class="whatif-metric-value">${val}</span>
                </div>`).join('')}`;
        grid.appendChild(card);
    });
}

// Initialise param fields on page load
(function initWhatIfDashboard() {
    // Defer until DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', updateWhatIfParams);
    } else {
        updateWhatIfParams();
    }
})();

// ============================================================================
// End of What-If Optimization Dashboard
// ============================================================================

// ============================================================================
// Feature 16: Constraint Graph Visualization
// ============================================================================

/** vis.js Network instance (kept so we can destroy/recreate on reload) */
let constraintGraphNetwork = null;

/**
 * loadConstraintGraph()
 * Fetch graph data from GET /api/constraint_graph and render with vis.js.
 */
async function loadConstraintGraph() {
    const container = document.getElementById('cg-container');
    const metricsEl = document.getElementById('cg-metrics');
    container.innerHTML = '<p class="empty-state">Loading graph&#8230;</p>';
    metricsEl.style.display = 'none';

    try {
        const response = await fetch(`${API_BASE_URL}/constraint_graph`);
        const data = await response.json();

        if (data.status !== 'success') {
            container.innerHTML = `<p class="empty-state error-state">Error: ${escapeHtml(data.message || 'Unknown error')}</p>`;
            return;
        }

        renderConstraintGraph(data.graph, container, metricsEl);
    } catch (err) {
        container.innerHTML = `<p class="empty-state error-state">Failed to load graph: ${escapeHtml(err.message)}</p>`;
    }
}

/**
 * renderConstraintGraph(graph, container, metricsEl)
 * Build vis.js nodes/edges datasets and initialise the Network.
 */
function renderConstraintGraph(graph, container, metricsEl) {
    // Destroy previous instance
    if (constraintGraphNetwork) {
        constraintGraphNetwork.destroy();
        constraintGraphNetwork = null;
    }

    const colorMap = {
        teacher:  { background: '#4fc3f7', border: '#0288d1', highlight: { background: '#81d4fa', border: '#0277bd' } },
        subject:  { background: '#a5d6a7', border: '#388e3c', highlight: { background: '#c8e6c9', border: '#2e7d32' } },
        room:     { background: '#ffcc80', border: '#ef6c00', highlight: { background: '#ffe0b2', border: '#e65100' } },
        timeslot: { background: '#ce93d8', border: '#7b1fa2', highlight: { background: '#e1bee7', border: '#6a1b9a' } }
    };

    const edgeColorMap = {
        qualification:    '#0288d1',
        room_requirement: '#ef6c00',
        availability:     '#7b1fa2'
    };

    // Build vis DataSets
    const visNodes = (graph.nodes || []).map(n => ({
        id:    n.id,
        label: n.label,
        group: n.group,
        color: colorMap[n.type] || { background: '#e0e0e0', border: '#9e9e9e' },
        font:  { size: 12 },
        shape: shapeForType(n.type)
    }));

    const visEdges = (graph.edges || []).map((e, i) => ({
        id:     i,
        from:   e.from,
        to:     e.to,
        label:  String(e.label || ''),
        color:  { color: edgeColorMap[e.type] || '#999', highlight: '#333' },
        arrows: 'to',
        font:   { size: 10, align: 'middle' },
        smooth: { type: 'curvedCW', roundness: 0.1 }
    }));

    const nodesDS = new vis.DataSet(visNodes);
    const edgesDS = new vis.DataSet(visEdges);

    // Clear container and render
    container.innerHTML = '';
    const options = {
        physics: {
            enabled: true,
            solver: 'forceAtlas2Based',
            forceAtlas2Based: { gravitationalConstant: -50, springLength: 120 }
        },
        interaction: { hover: true, zoomView: true, dragView: true },
        layout: { improvedLayout: true }
    };

    constraintGraphNetwork = new vis.Network(container, { nodes: nodesDS, edges: edgesDS }, options);

    // Highlight conflicts (nodes with degree > threshold)
    highlightConflictNodes(nodesDS, graph);

    // Show metrics
    displayGraphMetrics(graph.metrics, metricsEl);
}

/**
 * shapeForType(type) – map resource type to vis.js node shape
 */
function shapeForType(type) {
    const shapes = { teacher: 'ellipse', subject: 'box', room: 'diamond', timeslot: 'triangle' };
    return shapes[type] || 'dot';
}

/**
 * highlightConflictNodes(nodesDS, graph)
 * Nodes with unusually high degree are highlighted in red as potential conflicts.
 */
function highlightConflictNodes(nodesDS, graph) {
    const metrics = graph.metrics || {};
    const avgDegree = metrics.avg_degree || 0;
    const threshold = avgDegree * 2;
    const degrees = metrics.node_degrees || [];

    degrees.forEach(nd => {
        if (nd.degree > threshold && threshold > 0) {
            nodesDS.update({ id: nd.id, borderWidth: 3, color: { border: '#e53935' } });
        }
    });
}

/**
 * displayGraphMetrics(metrics, el)
 * Render summary metrics above the graph.
 */
function displayGraphMetrics(metrics, el) {
    if (!metrics) return;
    el.style.display = 'flex';
    el.innerHTML = `
        <div class="cg-metric-item"><span class="cg-metric-value">${metrics.node_count || 0}</span><span class="cg-metric-label">Nodes</span></div>
        <div class="cg-metric-item"><span class="cg-metric-value">${metrics.edge_count || 0}</span><span class="cg-metric-label">Edges</span></div>
        <div class="cg-metric-item"><span class="cg-metric-value">${(metrics.avg_degree || 0).toFixed(2)}</span><span class="cg-metric-label">Avg Degree</span></div>
    `;
}

// ============================================================================
// End of Constraint Graph Visualization
// ============================================================================

// ============================================================================
// Feature 17: AI Complexity Analysis
// ============================================================================

let _complexityData = null;

/**
 * loadComplexityAnalysis - Fetch complexity metrics from the API and render.
 */
async function loadComplexityAnalysis() {
    const loading = document.getElementById('complexity-loading');
    const metricsEl = document.getElementById('complexity-metrics');
    const chartsEl = document.getElementById('complexity-charts');
    const reportEl = document.getElementById('complexity-report');

    if (!loading) return;
    loading.style.display = 'flex';
    if (metricsEl) metricsEl.style.display = 'none';
    if (chartsEl) chartsEl.style.display = 'none';
    if (reportEl) reportEl.style.display = 'none';

    try {
        const res = await fetch(`${API_BASE_URL}/complexity_analysis`);
        const data = await res.json();
        if (data.status !== 'success') throw new Error(data.message || 'Failed');

        _complexityData = data;
        displayComplexityMetrics(data.metrics);
        renderComplexityCharts(data.metrics);
        displayComplexityReport(data.report);

        metricsEl.style.display = 'grid';
        chartsEl.style.display = 'flex';
        reportEl.style.display = 'block';
    } catch (err) {
        showNotification('Complexity analysis failed: ' + err.message, 'error');
    } finally {
        loading.style.display = 'none';
    }
}

/**
 * displayComplexityMetrics - Populate the metric cards.
 */
function displayComplexityMetrics(m) {
    const bf = (m.branching_factor || 0).toFixed(2);
    const depth = m.search_depth || {};
    const density = m.constraint_density || {};
    const tc = m.time_complexity || {};

    document.getElementById('cx-branching').textContent = bf;
    document.getElementById('cx-depth-max').textContent = depth.max_depth || '--';
    document.getElementById('cx-depth-avg').textContent = (depth.avg_depth || 0).toFixed(1);
    document.getElementById('cx-density').textContent = (density.density || 0).toFixed(2);
    document.getElementById('cx-bigo').textContent = tc.big_o || '--';
    document.getElementById('cx-nodes').textContent =
        `${m.nodes_explored || 0} / ${tc.theoretical_nodes || '?'}`;
}

/**
 * renderComplexityCharts - Draw bar chart and density pie chart on canvases.
 */
function renderComplexityCharts(m) {
    renderSearchSpaceChart(m);
    renderDensityChart(m);
}

function renderSearchSpaceChart(m) {
    const canvas = document.getElementById('cx-bar-chart');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const tc = m.time_complexity || {};
    const actual = m.nodes_explored || 0;
    const theoretical = Math.min(tc.theoretical_nodes || 0, 9999999);

    const maxVal = Math.max(actual, theoretical, 1);
    const barH = 40, gap = 20, padL = 140, padR = 20, padT = 20;
    const w = canvas.width - padL - padR;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.font = '13px sans-serif';

    const bars = [
        { label: 'Theoretical (capped)', value: theoretical, color: '#ef9a9a' },
        { label: 'Actual nodes', value: actual, color: '#81c784' }
    ];

    bars.forEach((b, i) => {
        const y = padT + i * (barH + gap);
        const bw = (b.value / maxVal) * w;

        ctx.fillStyle = b.color;
        ctx.fillRect(padL, y, bw, barH);

        ctx.fillStyle = '#424242';
        ctx.textAlign = 'right';
        ctx.fillText(b.label, padL - 8, y + barH / 2 + 5);

        ctx.textAlign = 'left';
        ctx.fillText(b.value.toLocaleString(), padL + bw + 6, y + barH / 2 + 5);
    });
}

function renderDensityChart(m) {
    const canvas = document.getElementById('cx-density-chart');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const density = m.constraint_density || {};
    const vars = density.variables || 0;
    const constrs = density.constraints || 0;

    const cx = canvas.width / 2, cy = canvas.height / 2, r = 80;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const total = vars + constrs || 1;
    const slices = [
        { label: 'Variables', value: vars, color: '#64b5f6' },
        { label: 'Constraints', value: constrs, color: '#ffb74d' }
    ];

    let startAngle = -Math.PI / 2;
    slices.forEach(s => {
        const angle = (s.value / total) * 2 * Math.PI;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.arc(cx, cy, r, startAngle, startAngle + angle);
        ctx.closePath();
        ctx.fillStyle = s.color;
        ctx.fill();
        startAngle += angle;
    });

    // Legend
    ctx.font = '12px sans-serif';
    slices.forEach((s, i) => {
        const lx = 10, ly = canvas.height - 30 + i * 18;
        ctx.fillStyle = s.color;
        ctx.fillRect(lx, ly - 10, 14, 14);
        ctx.fillStyle = '#424242';
        ctx.fillText(`${s.label}: ${s.value}`, lx + 18, ly);
    });
}

/**
 * displayComplexityReport - Show the text report.
 */
function displayComplexityReport(report) {
    const el = document.getElementById('complexity-report-text');
    if (el) el.textContent = report || 'No report available.';
}

/**
 * exportComplexityReport - Download the report as a text file.
 */
function exportComplexityReport() {
    if (!_complexityData || !_complexityData.report) {
        showNotification('Run complexity analysis first.', 'warning');
        return;
    }
    const blob = new Blob([_complexityData.report], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'complexity_report.txt';
    a.click();
    URL.revokeObjectURL(url);
}

// ============================================================================
// End of Complexity Analysis
// ============================================================================

// ============================================================================
// Feature 18: Natural Language Query Interface
// ============================================================================

/** In-memory query history (most recent first) */
let nlQueryHistory = [];

/**
 * submitNLQuery - Send a natural language query to the backend and display the answer.
 * @param {string} queryText - The natural language query string.
 */
async function submitNLQuery(queryText) {
    const trimmed = (queryText || '').trim();
    if (!trimmed) {
        showNotification('Please enter a query.', 'warning');
        return;
    }

    const answerContainer = document.getElementById('nl-answer-container');
    const answerText = document.getElementById('nl-answer-text');
    const intentBadge = document.getElementById('nl-answer-intent-badge');
    const submitBtn = document.getElementById('nl-query-submit');

    // Show loading state
    submitBtn.disabled = true;
    submitBtn.textContent = '...';
    answerContainer.style.display = 'none';

    try {
        const res = await fetch(`${API_BASE_URL}/nl_query`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ query: trimmed })
        });
        const data = await res.json();

        if (data.status === 'success') {
            const answer = data.answer || 'No answer available.';
            const intent = (data.intent || 'unknown').replace(/_/g, ' ');

            // Display answer
            answerText.textContent = answer;
            intentBadge.textContent = intent;
            answerContainer.style.display = 'block';

            // Add to history
            addToNLHistory(trimmed, answer, intent);
        } else {
            showNotification('Query failed: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (err) {
        showNotification('Network error: ' + err.message, 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Ask';
    }
}

/**
 * addToNLHistory - Add a query/answer pair to the history list.
 * @param {string} query - The query text.
 * @param {string} answer - The answer text.
 * @param {string} intent - The detected intent.
 */
function addToNLHistory(query, answer, intent) {
    // Prepend to history array (most recent first)
    nlQueryHistory.unshift({ query, answer, intent, timestamp: new Date() });

    // Keep only last 20 entries
    if (nlQueryHistory.length > 20) nlQueryHistory.pop();

    renderNLHistory();
}

/**
 * renderNLHistory - Render the query history list in the DOM.
 */
function renderNLHistory() {
    const container = document.getElementById('nl-history-container');
    const list = document.getElementById('nl-history-list');

    if (nlQueryHistory.length === 0) {
        container.style.display = 'none';
        return;
    }

    container.style.display = 'block';
    list.innerHTML = '';

    nlQueryHistory.forEach((item, idx) => {
        const li = document.createElement('li');
        li.className = 'nl-history-item';
        li.innerHTML = `
            <div class="nl-history-query">🔍 ${escapeHtml(item.query)}</div>
            <div class="nl-history-answer">${escapeHtml(item.answer.split('\n')[0])}</div>
        `;
        // Click to re-run query
        li.addEventListener('click', () => {
            const input = document.getElementById('nl-query-input');
            if (input) input.value = item.query;
            submitNLQuery(item.query);
        });
        list.appendChild(li);
    });
}

/**
 * escapeHtml - Escape HTML special characters to prevent XSS.
 * @param {string} text
 * @returns {string}
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(text));
    return div.innerHTML;
}

/**
 * initializeNLQuery - Wire up the NL Query submit button and example chips.
 * Called from DOMContentLoaded.
 */
function initializeNLQuery() {
    const submitBtn = document.getElementById('nl-query-submit');
    const input     = document.getElementById('nl-query-input');

    if (submitBtn) {
        submitBtn.addEventListener('click', () => {
            const query = input ? input.value : '';
            submitNLQuery(query);
        });
    }

    if (input) {
        input.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') submitNLQuery(input.value);
        });
    }

    // Wire example chips
    document.querySelectorAll('.nl-example-chip').forEach(chip => {
        chip.addEventListener('click', () => {
            const query = chip.getAttribute('data-query');
            if (input) input.value = query;
            submitNLQuery(query);
        });
    });
}

// ============================================================================
// Feature 19: AI Conflict Prediction
// ============================================================================

/**
 * initializeConflictPrediction()
 * Wire up the "Check for Conflicts", "Generate Anyway", and "Fix Issues First" buttons.
 * Called from DOMContentLoaded.
 */
function initializeConflictPrediction() {
    const checkBtn = document.getElementById('check-conflicts-btn');
    if (checkBtn) {
        checkBtn.addEventListener('click', checkConflicts);
    }

    // generate-anyway-btn is already wired in initializeGenerateSection — no double-bind here

    const fixIssuesBtn = document.getElementById('fix-issues-btn');
    if (fixIssuesBtn) {
        fixIssuesBtn.addEventListener('click', autoFixIssues);
    }
}

/**
 * autoFixIssues()
 * Reads the current bottleneck list, automatically adds missing rooms/timeslots,
 * bumps teacher maxload, re-submits to backend, then re-checks conflicts.
 */
async function autoFixIssues() {
    const fixIssuesBtn = document.getElementById('fix-issues-btn');
    if (fixIssuesBtn) {
        fixIssuesBtn.disabled = true;
        fixIssuesBtn.innerHTML = '<span class="btn-icon">⏳</span> Fixing…';
    }

    try {
        const types = ['teachers','subjects','rooms','timeslots','classes'];
        const hasData = types.every(t => resourceData[t].length > 0);
        if (!hasData) {
            showNotification('error', 'No resources loaded. Please load the example dataset first.');
            return;
        }

        let fixed = [];

        // --- Parse bottleneck items from DOM ---
        const bottleneckItems = document.querySelectorAll('#risk-bottlenecks-list .risk-bottleneck-item');
        const suggestionItems = document.querySelectorAll('#risk-suggestions-list .risk-suggestion-item');
        const allText = [...bottleneckItems, ...suggestionItems].map(el => el.textContent.toLowerCase()).join(' ');

        // 1. Theory room shortage → add Fix_Rooms classrooms
        if (allText.includes('theory') && (allText.includes('room shortage') || allText.includes('add more classroom'))) {
            const fixRooms = [
                { id: 'fix_r1', name: '1002', capacity: 72, type: 'classroom' },
                { id: 'fix_r2', name: '1003', capacity: 72, type: 'classroom' },
                { id: 'fix_r3', name: '1102', capacity: 72, type: 'classroom' },
                { id: 'fix_r4', name: '1103', capacity: 72, type: 'classroom' },
                { id: 'fix_r5', name: '1124', capacity: 72, type: 'classroom' },
                { id: 'fix_r6', name: '1125', capacity: 72, type: 'classroom' }
            ];
            const existingNames = new Set(resourceData.rooms.map(r => r.name));
            const toAdd = fixRooms.filter(r => !existingNames.has(r.name));
            resourceData.rooms.push(...toAdd);
            if (toAdd.length > 0) fixed.push(`Added ${toAdd.length} theory classrooms (${toAdd.map(r=>r.name).join(', ')})`);
        }

        // 2. Lab room shortage → add extra labs
        if (allText.includes('lab') && (allText.includes('room shortage') || allText.includes('add more lab'))) {
            const fixLabs = [
                { id: 'fix_l1', name: 'L-001', capacity: 30, type: 'lab' },
                { id: 'fix_l2', name: 'L-002', capacity: 30, type: 'lab' },
                { id: 'fix_l3', name: 'L-003', capacity: 30, type: 'lab' }
            ];
            const existingNames = new Set(resourceData.rooms.map(r => r.name));
            const toAdd = fixLabs.filter(r => !existingNames.has(r.name));
            resourceData.rooms.push(...toAdd);
            if (toAdd.length > 0) fixed.push(`Added ${toAdd.length} lab rooms (${toAdd.map(r=>r.name).join(', ')})`);
        }

        // 3. Timeslot shortage → extend to full day (45 slots, 9 periods × 5 days)
        if (allText.includes('timeslot') || allText.includes('time slot')) {
            const days = ['monday','tuesday','wednesday','thursday','friday'];
            const periods = [
                {p:1,t:'08:00'},{p:2,t:'09:00'},{p:3,t:'10:00'},{p:4,t:'11:00'},{p:5,t:'12:00'},
                {p:6,t:'14:00'},{p:7,t:'15:00'},{p:8,t:'16:00'},{p:9,t:'17:00'}
            ];
            const existingIds = new Set(resourceData.timeslots.map(s => s.id));
            let added = 0;
            days.forEach((day, di) => {
                periods.forEach(({p, t}) => {
                    const id = `slot${di*9 + p}`;
                    if (!existingIds.has(id)) {
                        resourceData.timeslots.push({ id, day, period: p, start: t, duration: 1 });
                        existingIds.add(id);
                        added++;
                    }
                });
            });
            if (added > 0) fixed.push(`Extended to ${resourceData.timeslots.length} timeslots (+${added} added)`);
        }

        // 4. Teacher overload → bump maxload to demand + 5
        const overloadMatches = allText.matchAll(/teacher\s+(\w+)\s+has\s+(\d+)\s+sessions/g);
        for (const m of overloadMatches) {
            const tid = m[1];
            const demand = parseInt(m[2]);
            const teacher = resourceData.teachers.find(t => t.id === tid || t.name.toLowerCase().includes(tid.toLowerCase()));
            if (teacher && teacher.maxload < demand) {
                teacher.maxload = demand + 5;
                fixed.push(`Increased ${teacher.name} maxload to ${teacher.maxload}`);
            }
        }
        // Also fix any teacher whose maxload < their session count based on bottleneck text
        const overloadItems = [...bottleneckItems].filter(el => el.textContent.toLowerCase().includes('teacher overload'));
        overloadItems.forEach(el => {
            const text = el.textContent;
            const nameMatch = text.match(/Prof\.\s+[\w\s]+/);
            const demandMatch = text.match(/has\s+(\d+)\s+sessions/);
            if (nameMatch && demandMatch) {
                const name = nameMatch[0].trim();
                const demand = parseInt(demandMatch[1]);
                const teacher = resourceData.teachers.find(t => t.name === name);
                if (teacher && teacher.maxload < demand) {
                    teacher.maxload = demand + 5;
                    fixed.push(`Increased ${teacher.name} maxload to ${teacher.maxload}`);
                }
            }
        });

        if (fixed.length === 0) {
            showNotification('info', 'No automatic fixes needed — resources look sufficient.');
        } else {
            showNotification('info', `Applied ${fixed.length} fix(es): ${fixed.join('; ')}`);
        }

        updateResourceCounts();
        updateGenResourceCounts();

        // Re-submit clean resourceData to backend
        const resp = await fetch(`${API_BASE_URL}/resources`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(resourceData)
        });
        const result = await resp.json();
        if (!resp.ok) throw new Error(result.message || 'Failed to submit');
        _resourcesSubmittedToBackend = true;

        // Re-run conflict check
        await checkConflicts();

        // Check if all clear
        const remaining = document.querySelectorAll('#risk-bottlenecks-list .risk-bottleneck-item');
        if (remaining.length === 0) {
            showNotification('success', '✅ All issues resolved — ready to generate!');
        }

    } catch (err) {
        showNotification('error', `Fix failed: ${err.message}`);
    } finally {
        if (fixIssuesBtn) {
            fixIssuesBtn.disabled = false;
            fixIssuesBtn.innerHTML = '<span class="btn-icon">🔧</span> Fix Issues First';
        }
    }
}

/**
 * checkConflicts()
 * Calls POST /api/predict_conflicts and renders the risk assessment report.
 */
async function checkConflicts() {
    // Auto-submit resources if data is loaded but not yet sent to backend
    if (!_resourcesSubmittedToBackend) {
        const types = ['teachers','subjects','rooms','timeslots','classes'];
        const hasData = types.every(t => resourceData[t].length > 0);
        if (!hasData) {
            showNotification('error', 'Please load or add resources first before checking for conflicts.');
            return;
        }
        try {
            const r = await fetch(`${API_BASE_URL}/resources`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(resourceData)
            });
            if (!r.ok) throw new Error('Failed to submit resources');
            _resourcesSubmittedToBackend = true;
        } catch (e) {
            showNotification('error', `Could not submit resources: ${e.message}`);
            return;
        }
    }

    const loading = document.getElementById('risk-loading');
    const report  = document.getElementById('risk-report');
    const checkBtn = document.getElementById('check-conflicts-btn');

    loading.style.display = 'block';
    report.style.display  = 'none';
    checkBtn.disabled = true;

    try {
        const response = await fetch(`${API_BASE_URL}/predict_conflicts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})   // required for POST (Req 3.1)
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to predict conflicts');
        }

        const result = await response.json();
        displayRiskAssessment(result);

    } catch (error) {
        showNotification('error', `Conflict prediction failed: ${error.message}`);
    } finally {
        loading.style.display = 'none';
        checkBtn.disabled = false;
    }
}

/**
 * displayRiskAssessment(data)
 * Renders the full risk report from the API response.
 *
 * @param {Object} data - API response with risk_level, conflict_probability,
 *                        bottlenecks, suggestions fields.
 */
function displayRiskAssessment(data) {
    const report = document.getElementById('risk-report');

    // Risk level badge
    const riskLevel = (data.risk_level || 'unknown').toLowerCase();
    const badge = document.getElementById('risk-level-badge');
    badge.textContent = riskLevel.charAt(0).toUpperCase() + riskLevel.slice(1);
    badge.className = `risk-level-badge ${riskLevel}`;

    // Conflict probability
    const prob = data.conflict_probability;
    const probEl = document.getElementById('risk-probability-value');
    if (prob !== undefined && prob !== null) {
        const pct = typeof prob === 'number' ? (prob * 100).toFixed(0) + '%' : prob;
        probEl.textContent = pct;
    } else {
        probEl.textContent = 'N/A';
    }

    // Bottlenecks
    displayBottlenecks(data.bottlenecks || []);

    // Suggestions
    displaySuggestions(data.suggestions || []);

    report.style.display = 'block';
}

/**
 * displayBottlenecks(bottlenecks)
 * Renders the bottleneck resource warnings.
 *
 * @param {Array} bottlenecks - Array of bottleneck strings or objects.
 */
function displayBottlenecks(bottlenecks) {
    const section = document.getElementById('risk-bottlenecks-section');
    const list    = document.getElementById('risk-bottlenecks-list');

    if (!bottlenecks || bottlenecks.length === 0) {
        section.style.display = 'none';
        return;
    }

    list.innerHTML = '';
    bottlenecks.forEach(item => {
        const li = document.createElement('li');
        li.className = 'risk-bottleneck-item';

        let text = '';
        let actionBtn = null;

        if (typeof item === 'string') {
            text = item;
            // Parse string-based room shortage messages
            const theoryMatch = item.match(/theory.*?(\d+)\s+session.*?(\d+)\s+avail/i);
            const labMatch    = item.match(/lab.*?(\d+)\s+session.*?(\d+)\s+avail/i);
            if (theoryMatch || item.toLowerCase().includes('theory')) {
                actionBtn = _makeBottleneckBtn('➕ Add Theory Room', () => quickAddRoom('classroom'));
            } else if (labMatch || item.toLowerCase().includes('lab')) {
                actionBtn = _makeBottleneckBtn('➕ Add Lab Room', () => quickAddRoom('lab'));
            }
        } else if (item.description) {
            text = item.description;
        } else if (item.type === 'room_bottleneck') {
            const rtype = item.room_type || 'classroom';
            const needed = (item.demand || 0) - (item.supply || 0);
            text = `Room shortage (${rtype}): ${item.demand} sessions need ${rtype} rooms but only ${item.supply} available`;
            const btnLabel = rtype === 'lab' ? '➕ Add Lab Room' : '➕ Add Theory Room';
            const addType  = rtype === 'lab' ? 'lab' : 'classroom';
            actionBtn = _makeBottleneckBtn(btnLabel, () => quickAddRoom(addType, needed));
        } else if (item.type === 'teacher_bottleneck') {
            text = `Teacher overload: ${item.name || item.teacher_id} has ${item.demand} sessions but max load is ${item.max_load}`;
        } else if (item.type === 'timeslot_bottleneck') {
            text = `Timeslot shortage: ${item.demand} sessions needed but only ${item.supply} slots available`;
            actionBtn = _makeBottleneckBtn('➕ Add Time Slots', () => {
                switchSection('resources');
                document.querySelectorAll('.nav-btn').forEach(b =>
                    b.classList.toggle('active', b.getAttribute('data-section') === 'resources'));
                showNotification('info', 'Add more time slots in the Resources section.');
            });
        } else {
            text = JSON.stringify(item);
        }

        const span = document.createElement('span');
        span.style.flex = '1';
        span.textContent = text;
        li.appendChild(span);
        if (actionBtn) li.appendChild(actionBtn);
        list.appendChild(li);
    });

    section.style.display = 'block';
}

/** Create a small action button for a bottleneck row */
function _makeBottleneckBtn(label, onClick) {
    const btn = document.createElement('button');
    btn.textContent = label;
    btn.className = 'bottleneck-action-btn';
    btn.addEventListener('click', onClick);
    return btn;
}

/**
 * quickAddRoom(roomType, needed)
 * Shows an inline quick-add form inside the risk report so the user can
 * add rooms without leaving the generate section.
 *
 * @param {string} roomType - 'classroom' or 'lab'
 * @param {number} needed   - how many more rooms are needed (hint only)
 */
function quickAddRoom(roomType, needed) {
    const containerId = `quick-add-room-${roomType}`;
    // Toggle: if already open, close it
    const existing = document.getElementById(containerId);
    if (existing) { existing.remove(); return; }

    const typeLabel = roomType === 'lab' ? 'Lab' : 'Theory';
    const container = document.createElement('div');
    container.id = containerId;
    container.className = 'quick-add-room-form';
    container.innerHTML = `
        <h5>➕ Add ${typeLabel} Room</h5>
        ${needed > 0 ? `<p class="quick-add-hint">You need at least ${needed} more ${typeLabel.toLowerCase()} room(s).</p>` : ''}
        <div class="quick-add-fields">
            <input type="text" id="qar-name-${roomType}" placeholder="Room name (e.g. ${roomType === 'lab' ? 'Lab C' : 'Room 104'})" />
            <input type="number" id="qar-cap-${roomType}" placeholder="Capacity" min="10" max="300" value="40" />
            <button class="btn btn-success btn-sm" onclick="confirmQuickAddRoom('${roomType}')">✔ Add Room</button>
            <button class="btn btn-secondary btn-sm" onclick="document.getElementById('${containerId}').remove()">✕</button>
        </div>`;

    // Insert after the bottleneck item that triggered this
    const list = document.getElementById('risk-bottlenecks-list');
    list.after(container);
    document.getElementById(`qar-name-${roomType}`).focus();
}

/**
 * confirmQuickAddRoom(roomType)
 * Reads the quick-add form, pushes the room into resourceData, and re-submits.
 */
async function confirmQuickAddRoom(roomType) {
    const nameEl = document.getElementById(`qar-name-${roomType}`);
    const capEl  = document.getElementById(`qar-cap-${roomType}`);
    const name   = (nameEl.value || '').trim();
    const cap    = parseInt(capEl.value) || 40;

    if (!name) {
        showNotification('error', 'Please enter a room name.');
        nameEl.focus();
        return;
    }

    const room = { id: `room_${Date.now()}`, name, capacity: cap, type: roomType };
    resourceData.rooms.push(room);
    updateResourceCounts();
    updateGenResourceCounts();

    // Remove the quick-add form
    const container = document.getElementById(`quick-add-room-${roomType}`);
    if (container) container.remove();

    showNotification('info', `Room "${name}" added. Re-submitting to backend…`);

    // Auto re-submit
    try {
        const response = await fetch(`${API_BASE_URL}/resources`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(resourceData)
        });
        const result = await response.json();
        if (!response.ok) throw new Error(result.message || 'Failed');
        showNotification('success', `Room "${name}" added and resources re-submitted. You can now generate the timetable.`);
        // Refresh the conflict check so the bottleneck list updates
        checkConflicts();
    } catch (err) {
        showNotification('error', `Re-submit failed: ${err.message}`);
    }
}

/**
 * displaySuggestions(suggestions)
 * Renders the preventive action suggestions.
 *
 * @param {Array} suggestions - Array of suggestion strings or objects.
 */
function displaySuggestions(suggestions) {
    const section = document.getElementById('risk-suggestions-section');
    const list    = document.getElementById('risk-suggestions-list');

    if (!suggestions || suggestions.length === 0) {
        section.style.display = 'none';
        return;
    }

    list.innerHTML = '';
    suggestions.forEach(item => {
        const li = document.createElement('li');
        li.className = 'risk-suggestion-item';

        const text = typeof item === 'string' ? item : (item.description || JSON.stringify(item));
        const priority = item.priority || '';

        // Priority badge
        const badge = document.createElement('span');
        badge.className = `suggestion-priority suggestion-priority--${priority}`;
        badge.textContent = priority || 'info';

        const textSpan = document.createElement('span');
        textSpan.className = 'suggestion-text';
        textSpan.textContent = text;

        li.appendChild(badge);
        li.appendChild(textSpan);

        // Attach the right action button based on description content
        const btn = _suggestionActionBtn(text);
        if (btn) li.appendChild(btn);

        list.appendChild(li);
    });

    section.style.display = 'block';
}

/**
 * _suggestionActionBtn(text)
 * Returns an action button appropriate for the given suggestion text, or null.
 */
function _suggestionActionBtn(text) {
    const t = text.toLowerCase();

    // "Add more classrooms: N theory sessions..."
    if (t.includes('add more classrooms') || t.includes('theory sessions')) {
        return _makeBottleneckBtn('➕ Add Theory Room', () => quickAddRoom('classroom'));
    }
    // "Add more lab rooms: N lab sessions..."
    if (t.includes('add more lab') || (t.includes('lab') && t.includes('add'))) {
        return _makeBottleneckBtn('➕ Add Lab Room', () => quickAddRoom('lab'));
    }
    // "Add a [type] room for subject..."
    if (t.match(/add a (lab|classroom|theory) room/)) {
        const isLab = t.includes('lab');
        return _makeBottleneckBtn(isLab ? '➕ Add Lab Room' : '➕ Add Theory Room',
            () => quickAddRoom(isLab ? 'lab' : 'classroom'));
    }
    // "Room shortage for [type] sessions: N needed..."
    if (t.includes('room shortage')) {
        const isLab = t.includes('lab');
        return _makeBottleneckBtn(isLab ? '➕ Add Lab Room' : '➕ Add Theory Room',
            () => quickAddRoom(isLab ? 'lab' : 'classroom'));
    }
    // "Add more timeslots" or "Timeslot pressure"
    if (t.includes('timeslot') || t.includes('time slot')) {
        return _makeBottleneckBtn('➕ Add Time Slots', () => {
            switchSection('resources');
            document.querySelectorAll('.nav-btn').forEach(b =>
                b.classList.toggle('active', b.getAttribute('data-section') === 'resources'));
            showNotification('info', 'Scroll to the Time Slots section and add more slots.');
        });
    }
    // "Assign a qualified teacher for subject sX"
    if (t.includes('assign') && t.includes('teacher')) {
        return _makeBottleneckBtn('✏️ Edit Teachers', () => {
            switchSection('resources');
            document.querySelectorAll('.nav-btn').forEach(b =>
                b.classList.toggle('active', b.getAttribute('data-section') === 'resources'));
            showNotification('info', 'Update teacher subject assignments in the Teachers section.');
        });
    }
    // "Teacher tX has N sessions... Extend availability or reduce load"
    if (t.includes('extend availability') || t.includes('reduce load')) {
        return _makeBottleneckBtn('✏️ Edit Teacher Load', () => {
            // Open inline editor on Teachers tab
            const editPanel = document.getElementById('gen-edit-panel');
            const toggleBtn = document.getElementById('gen-edit-toggle-btn');
            if (editPanel && editPanel.style.display === 'none') {
                editPanel.style.display = 'block';
                if (toggleBtn) toggleBtn.textContent = '✖ Close Editor';
            }
            switchGenTab('teachers');
            if (editPanel) editPanel.scrollIntoView({ behavior: 'smooth', block: 'start' });
            showNotification('info', 'Remove or adjust teachers with excessive load, then re-submit.');
        });
    }

    return null;
}

// ============================================================================
// End of Feature 19: AI Conflict Prediction
// ============================================================================

// ============================================================================
// Feature 20: Timetable Versioning System
// ============================================================================

/**
 * Initialize versioning UI event listeners.
 */
function initializeVersioning() {
    const saveBtn    = document.getElementById('save-version-btn');
    const refreshBtn = document.getElementById('refresh-versions-btn');
    const compareBtn = document.getElementById('compare-versions-btn');

    if (saveBtn)    saveBtn.addEventListener('click', saveCurrentVersion);
    if (refreshBtn) refreshBtn.addEventListener('click', loadVersionList);
    if (compareBtn) compareBtn.addEventListener('click', compareSelectedVersions);

    // Load version list when the Versions section becomes active
    document.querySelectorAll('.nav-btn').forEach(btn => {
        if (btn.dataset.section === 'versions') {
            btn.addEventListener('click', loadVersionList);
        }
    });
}

/**
 * Save the current timetable as a new version.
 */
async function saveCurrentVersion() {
    const author = document.getElementById('version-author')?.value.trim() || 'user';
    const reason = document.getElementById('version-reason')?.value.trim() || 'manual save';

    try {
        const response = await fetch(`${API_BASE_URL}/save_version`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ author, reason })
        });
        const result = await response.json();

        if (result.status === 'success') {
            showNotification(`Version ${result.version_id} saved successfully`, 'success');
            loadVersionList();
        } else {
            showNotification('Error saving version: ' + result.message, 'error');
        }
    } catch (err) {
        showNotification('Network error: ' + err.message, 'error');
    }
}

/**
 * Load and display the version history timeline.
 */
async function loadVersionList() {
    const timeline = document.getElementById('version-timeline');
    if (!timeline) return;

    try {
        const response = await fetch(`${API_BASE_URL}/versions`);
        const result   = await response.json();

        if (result.status === 'success') {
            renderVersionTimeline(result.versions || []);
            populateVersionSelects(result.versions || []);
        } else {
            timeline.innerHTML = `<p class="error-state">${result.message}</p>`;
        }
    } catch (err) {
        timeline.innerHTML = `<p class="error-state">Failed to load versions: ${err.message}</p>`;
    }
}

/**
 * Render the version timeline in the UI.
 * @param {Array} versions - Array of version metadata objects.
 */
function renderVersionTimeline(versions) {
    const timeline = document.getElementById('version-timeline');
    if (!timeline) return;

    if (!versions || versions.length === 0) {
        timeline.innerHTML = '<p class="empty-state">No versions saved yet. Generate a timetable and save it.</p>';
        return;
    }

    timeline.innerHTML = versions.map(meta => {
        const vid       = meta.version_id || '?';
        const ts        = meta.timestamp  || '';
        const author    = meta.author     || 'unknown';
        const reason    = meta.reason     || '';

        return `
        <div class="version-entry" data-version-id="${vid}">
            <div class="version-entry-info">
                <div class="version-entry-id">📌 ${vid}</div>
                <div class="version-entry-timestamp">🕐 ${ts}</div>
                <div class="version-entry-meta">👤 ${author} — ${reason}</div>
            </div>
            <div class="version-entry-actions">
                <button class="btn btn-secondary btn-sm" onclick="loadAndPreviewVersion('${vid}')">👁 View</button>
                <button class="btn btn-primary btn-sm" onclick="rollbackToVersion('${vid}')">↩ Restore</button>
            </div>
        </div>`;
    }).join('');
}

/**
 * Populate the version comparison dropdowns.
 * @param {Array} versions - Array of version metadata objects.
 */
function populateVersionSelects(versions) {
    const selA = document.getElementById('compare-version-a');
    const selB = document.getElementById('compare-version-b');
    if (!selA || !selB) return;

    const options = versions.map(m =>
        `<option value="${m.version_id}">${m.version_id} — ${m.timestamp || ''}</option>`
    ).join('');

    selA.innerHTML = '<option value="">Select version A...</option>' + options;
    selB.innerHTML = '<option value="">Select version B...</option>' + options;
}

/**
 * Load a specific version and display its timetable.
 * @param {string} versionId - The version ID to load.
 */
async function loadAndPreviewVersion(versionId) {
    try {
        const response = await fetch(`${API_BASE_URL}/version?id=${encodeURIComponent(versionId)}`);
        const result   = await response.json();

        if (result.status === 'success') {
            // Update current timetable display
            currentTimetable = result.timetable;
            renderTimetable(result.timetable);
            showNotification(`Previewing version ${versionId}`, 'info');
            // Switch to visualize section
            const visBtn = document.querySelector('.nav-btn[data-section="visualize"]');
            if (visBtn) visBtn.click();
        } else {
            showNotification('Error loading version: ' + result.message, 'error');
        }
    } catch (err) {
        showNotification('Network error: ' + err.message, 'error');
    }
}

/**
 * Roll back the current timetable to a saved version.
 * @param {string} versionId - The version ID to restore.
 */
async function rollbackToVersion(versionId) {
    if (!confirm(`Restore timetable to version ${versionId}? The current timetable will be replaced.`)) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/rollback`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ version_id: versionId })
        });
        const result = await response.json();

        if (result.status === 'success') {
            currentTimetable  = result.timetable;
            currentReliability = result.reliability;
            renderTimetable(result.timetable);
            updateReliabilityDisplay(result.reliability);
            showNotification(`Rolled back to version ${versionId}`, 'success');
            // Switch to visualize section
            const visBtn = document.querySelector('.nav-btn[data-section="visualize"]');
            if (visBtn) visBtn.click();
        } else {
            showNotification('Rollback failed: ' + result.message, 'error');
        }
    } catch (err) {
        showNotification('Network error: ' + err.message, 'error');
    }
}

/**
 * Compare two selected versions and display the diff.
 */
async function compareSelectedVersions() {
    const versionA = document.getElementById('compare-version-a')?.value;
    const versionB = document.getElementById('compare-version-b')?.value;

    if (!versionA || !versionB) {
        showNotification('Please select both versions to compare', 'warning');
        return;
    }
    if (versionA === versionB) {
        showNotification('Please select two different versions', 'warning');
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/compare_versions`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ version_a: versionA, version_b: versionB })
        });
        const result = await response.json();

        if (result.status === 'success') {
            renderVersionDiff(result.diff);
        } else {
            showNotification('Comparison failed: ' + result.message, 'error');
        }
    } catch (err) {
        showNotification('Network error: ' + err.message, 'error');
    }
}

/**
 * Render the version diff result in the UI.
 * @param {Object} diff - The diff object returned by the API.
 */
function renderVersionDiff(diff) {
    const container = document.getElementById('version-diff-result');
    if (!container) return;

    const metaA = diff.meta_a || {};
    const metaB = diff.meta_b || {};

    const addedItems   = (diff.added   || []).slice(0, 20);
    const removedItems = (diff.removed || []).slice(0, 20);

    const formatAssignment = a =>
        `${a.class_id || '?'} / ${a.subject_id || '?'} → ${a.teacher_id || '?'} @ ${a.room_id || '?'} [${a.slot_id || '?'}]`;

    container.innerHTML = `
        <div class="version-diff-header">
            <div>
                <strong>${diff.version_a}</strong>
                <div style="font-size:0.8rem;color:#6c757d;">${metaA.timestamp || ''} — ${metaA.reason || ''}</div>
            </div>
            <div style="font-size:1.5rem;">⚖</div>
            <div>
                <strong>${diff.version_b}</strong>
                <div style="font-size:0.8rem;color:#6c757d;">${metaB.timestamp || ''} — ${metaB.reason || ''}</div>
            </div>
        </div>
        <div class="version-diff-header">
            <div class="version-diff-stat added">
                <span class="stat-count">+${diff.added_count || 0}</span>
                <span class="stat-label">Added</span>
            </div>
            <div class="version-diff-stat removed">
                <span class="stat-count">-${diff.removed_count || 0}</span>
                <span class="stat-label">Removed</span>
            </div>
            <div class="version-diff-stat same">
                <span class="stat-count">${diff.unchanged_count || 0}</span>
                <span class="stat-label">Unchanged</span>
            </div>
        </div>
        ${addedItems.length > 0 ? `
        <div class="version-diff-assignments">
            <h5>Added in ${diff.version_b}</h5>
            <ul class="version-diff-list added-list">
                ${addedItems.map(a => `<li>+ ${formatAssignment(a)}</li>`).join('')}
                ${diff.added_count > 20 ? `<li>… and ${diff.added_count - 20} more</li>` : ''}
            </ul>
        </div>` : ''}
        ${removedItems.length > 0 ? `
        <div class="version-diff-assignments">
            <h5>Removed from ${diff.version_a}</h5>
            <ul class="version-diff-list removed-list">
                ${removedItems.map(a => `<li>- ${formatAssignment(a)}</li>`).join('')}
                ${diff.removed_count > 20 ? `<li>… and ${diff.removed_count - 20} more</li>` : ''}
            </ul>
        </div>` : ''}
    `;

    container.style.display = 'block';
}

// initializeVersioning is called from main DOMContentLoaded

// ============================================================================
// End of Feature 20: Timetable Versioning System
// ============================================================================

// ============================================================================
// Aliases for auto-load compatibility
// ============================================================================
const loadVersions = loadVersionList;
const updateWhatIfDashboard = (typeof runWhatIfAnalysis === 'function') ? runWhatIfAnalysis : function() {};
