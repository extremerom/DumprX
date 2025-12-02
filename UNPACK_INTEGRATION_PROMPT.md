# Copilot Prompt: UNPACK Integration from MIO-KITCHEN

This document provides comprehensive guidelines for integrating UNPACK logic from the MIO-KITCHEN-SOURCE repository into DumprX.

---

## Comprehensive Analysis Requirements

BEFORE ANY IMPLEMENTATION, ANALYZE:

### 1. Current Project Analysis
   - Examine complete current project structure and architecture
   - Document all existing UNPACK logic and functions
   - Identify current extraction system and patterns
   - Study logging system (format, levels, output location)
   - Map all configuration files and settings
   - Analyze error handling patterns
   - Review import structure and module organization
   - Document all utility functions and helpers
   - Identify code conventions and naming patterns

### 2. Remote Repository Analysis
   - Examine complete MIO-KITCHEN-SOURCE structure
   - Document all UNPACK-related logic and functions
   - Identify extraction system and implementation patterns
   - Study logging system used in remote repository
   - Analyze how remote repository handles errors
   - Review dependencies and external tools
   - Study file organization and module structure
   - Document all utility functions available
   - Identify code conventions in remote repository

### 3. Comparison and Planning
   - Compare extraction logic between projects
   - Compare logging systems between projects
   - Identify functional gaps in current project
   - List duplicated functionality
   - Create integration strategy document
   - Plan how to unify logging systems
   - Determine required modifications per module
   - Identify potential conflicts or incompatibilities

---

## Refactoring Rules

### MANDATORY

1. NO Wrapper Functions for Python Imports
   - ABSOLUTELY DO NOT create wrapper functions that call imported .py files
   - ABSOLUTELY DO NOT create intermediate functions that redirect to imported modules
   - Import functions directly and use them without wrapping
   - If imported function needs modification, modify it directly in source
   - Never create functions like: def wrapper_unpack() that just calls imported unpack()
   - Exception: Only create wrapper if business logic changes are needed, not just function calls

2. Modify Imported Python Files for Project Integration
   - DO modify all imported .py files to match current project logic
   - Update all imports in imported .py files to use current project paths
   - Replace logging system in imported .py with current project logging
   - Adapt file extraction methods to match current project extraction system
   - Modify error handling to match current project error handling patterns
   - Update configuration references to use current project config system
   - Adapt any temporary file handling to match current project standards
   - Ensure all imported code follows current project code conventions
   - Modify output paths and naming to match current project standards
   - Test each imported function to ensure it works with project logging system

3. Unify Logging System
   - Identify exact logging implementation in current project
   - Replace ALL logging in imported .py files with current project logging
   - Ensure all imported modules use same logger instance
   - Verify log levels match current project standards
   - Confirm log output format matches current project format
   - Test logging output from all imported modules

4. Unify Extraction System
   - Identify how current project extracts and processes files
   - Modify imported .py extraction logic to match current project system
   - Ensure all imported modules follow same extraction workflow
   - Verify temporary file handling matches current project
   - Confirm output structure matches current project standards

5. Refactor .sh and .py Files
   - Adapt remote repository scripts to work under same logic as current project
   - Convert shell scripts to Python if necessary for consistency
   - Unify coding styles and naming conventions
   - Maintain original functionality but improve structure
   - Ensure refactored scripts use current project logging system

6. Remove Residual Files
   - Delete duplicate or unnecessary files
   - Remove old backups (.bak, .old, etc.)
   - Clean temporary directories that are not used
   - Keep only what is essential and functional

7. Adapt to Project Structure
   - Respect current directory structure
   - Follow project import patterns
   - Maintain module naming consistency
   - Integrate into existing configuration system

---

## Code Standards

### Python - Direct Integration (NO Wrappers)
```python
# CORRECT - Direct import and use
from utils.unpack import unpack_sparse_image

result = unpack_sparse_image(file_path)
if not result:
    raise UnpackError("Failed to unpack image")

# CORRECT - Modify imported function directly
# Instead of creating wrapper, modify the imported function:
# Edit unpack_sparse_image() in utils/unpack.py to use project logging

# INCORRECT - Creating wrapper is forbidden
def wrapper_unpack(file_path):
    return unpack_sparse_image(file_path)

# INCORRECT - Creating intermediate function for imported module
def execute_unpack(file_path):
    return unpack_sparse_image(file_path)

# INCORRECT - Wrapper that adds logging
def wrapper_with_logging(file_path):
    log.info("Starting unpack")
    result = unpack_sparse_image(file_path)
    log.info("Unpack complete")
    return result

# INCORRECT - Not safe
import subprocess
subprocess.call(['tool', 'arg'])

# CORRECT
result = subprocess.run(['tool', 'arg'], check=True)

# CORRECT - Modify imported .py to use project logging
# In imported unpack.py file, replace:
#   print("Unpacking...")
# With:
#   from project.logger import get_logger
#   logger = get_logger(__name__)
#   logger.info("Unpacking...")
```

### Python - Imported Module Modification Pattern
```python
# ORIGINAL imported .py (from MIO-KITCHEN)
import logging
logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger(__name__)

def unpack_image(path):
    log.debug("Starting unpack")
    return process_image(path)

# MODIFIED for project integration
from project.logger import get_logger  # Use project logger
logger = get_logger(__name__)

def unpack_image(path):
    logger.debug("Starting unpack")  # Use project logging
    return process_image(path)
```

---

## Getting Started

EXECUTION ORDER:

STEP 1: PROJECT ANALYSIS
1. Clone and analyze current project completely
2. Document current project structure
3. Document current logging system details
4. Document current extraction system details
5. List all current UNPACK functions and logic
6. Create current project analysis report

STEP 2: REMOTE REPOSITORY ANALYSIS
1. Clone MIO-KITCHEN-SOURCE repository
2. Document remote repository structure
3. Document remote logging system
4. Document remote extraction system
5. List all UNPACK-related functions and logic
6. Create remote repository analysis report

STEP 3: COMPARISON AND PLANNING
1. Compare both analyses
2. Identify gaps and overlaps
3. Plan integration strategy
4. Document required changes per module
5. Plan logging system unification
6. Create integration plan document

STEP 4: IMPLEMENTATION
1. Import required .py files from remote
2. Modify all imported .py to match project standards
3. Update logging in all imported modules
4. Update extraction logic in imported modules
5. Replace or eliminate duplicated code
6. Implement missing functionality
7. NO wrapper functions - modify imported code directly

When ready, provide:
1. Path of current project (local structure)
2. Access to remote repository (already available: MIO-KITCHEN-SOURCE)
3. Python/System compatibility specifications
4. Project-specific requirements

Ready to analyze and implement!

---

Last Updated: December 2025
Project: UNPACK Logic Integration from MIO-KITCHEN
Prompt Version: 2.2
