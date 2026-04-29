# AI-Based Timetable Generation System - Startup Guide

## Quick Start

### Starting the System

To start the AI-Based Timetable Generation System, run:

```bash
swipl main.pl
```

The system will:
1. Check for required Prolog libraries
2. Load configuration from `config.pl`
3. Load all backend modules in dependency order
4. Initialize the logging system
5. Load example dataset from `data/dataset.pl`
6. Start the HTTP server on port 8080 (default)

### Expected Output

```
===========================================
AI-Based Timetable Generation System
===========================================

Checking required libraries...
  Checking Prolog libraries...
    ✓ HTTP Server (http/http_server)
    ✓ JSON Support (http/http_json)
    ✓ CORS Support (http/http_cors)
    ✓ List Operations (lists)
All required libraries are available.

Initializing logging system...
  Log level set to: info

Configuration:
  - Server Port: 8080
  - Log Level: info
  - Max Search Nodes: 10000
  - Search Timeout: 120 seconds

Verifying backend modules...
  ✓ logging.pl loaded
  ✓ knowledge_base.pl loaded
  ✓ matrix_model.pl loaded
  ✓ constraints.pl loaded
  ✓ csp_solver.pl loaded
  ✓ probability_module.pl loaded
  ✓ timetable_generator.pl loaded
  ✓ api_server.pl loaded
  ✓ All backend modules loaded successfully

Checking for example dataset...
  ✓ Dataset loaded: 5 teachers found

Starting HTTP server...
  ✓ Server started successfully

===========================================
Server URL: http://localhost:8080
API Endpoints:
  POST /api/resources   - Submit resource data
  POST /api/generate    - Generate timetable
  GET  /api/timetable   - Retrieve timetable
  GET  /api/reliability - Get reliability score
  POST /api/explain     - Get assignment explanation
  GET  /api/conflicts   - Detect conflicts
  POST /api/repair      - Repair timetable
  GET  /api/analytics   - Get analytics
  GET  /api/export      - Export timetable
===========================================

System ready. Press Ctrl+C to stop.
```

## Configuration

### Changing Server Port

Edit `config.pl` and modify:

```prolog
server_port(8080).  % Change to desired port
```

### Changing Log Level

Edit `config.pl` and modify:

```prolog
log_level(info).  % Options: debug, info, warning, error
```

### Other Configuration Options

See `config.pl` for all available configuration options including:
- CSP solver settings (max search nodes, timeout)
- Probability module settings (availability probabilities)
- Soft constraint weights
- Export settings

## Troubleshooting

### Missing Libraries

If you see errors about missing libraries:

```
✗ HTTP Server (http/http_server) - MISSING
```

Install the required libraries:

```bash
swipl
?- pack_install(http).
```

Or ensure you have a complete SWI-Prolog installation from:
https://www.swi-prolog.org/download/stable

### Module Loading Errors

If a backend module fails to load, check:
1. The file exists in the `backend/` directory
2. The file has no syntax errors
3. Dependencies are loaded in correct order

### Dataset Not Found

If you see:

```
⚠ No dataset loaded. Use data/dataset.pl to add example data.
```

This is a warning, not an error. The system will start but you'll need to submit resource data via the API before generating timetables.

To use the example dataset, ensure `data/dataset.pl` exists.

## Testing the System

### Run Integration Tests

```bash
swipl -s test_main_integration.pl
```

This will verify:
- Configuration is loaded correctly
- All backend modules are loaded
- Dataset is accessible
- Module dependencies work

### Test API Endpoints

Use curl or Postman to test the API:

```bash
# Test server is running
curl http://localhost:8080/api/timetable

# Generate a timetable
curl -X POST http://localhost:8080/api/generate

# Get reliability score
curl http://localhost:8080/api/reliability
```

## Stopping the System

Press `Ctrl+C` in the terminal where the system is running, then type `halt.` to exit cleanly.

## Next Steps

1. Open the web interface at `http://localhost:8080` (once frontend is implemented)
2. Submit resource data via the API or web interface
3. Generate timetables
4. View and analyze results

For more information, see:
- `docs/README.md` - Full documentation
- `docs/ARCHITECTURE.md` - System architecture
- `.kiro/specs/ai-timetable-generation/` - Complete specification
