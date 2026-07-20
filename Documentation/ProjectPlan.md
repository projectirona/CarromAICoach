Below are two deliverables:

1. A complete project plan.
2. A master prompt for an agentic AI coding system that instructs it to read the project plan from a local file path and implement the application incrementally.

# Carrom AI Coach
## Complete Project Plan (Version 1.0)

# Project Vision

Develop an offline iPhone application that acts as an AI coach for carrom players.

The application does not provide continuous AR during gameplay.

Instead, it follows a simple workflow:

Scan → Analyze → Recommend → Play → Scan Again

The player naturally plays the game while the AI provides strategic recommendations before each shot.

The application is optimized for:

- iPhone 15 Plus
- One fixed 52-inch board
- One fixed 75 mm striker
- Offline operation
- Single-player coaching
- Minimal interface

---

# User Workflow

1. Launch the application.
2. Select player color:
   - Black
   - White
3. AI remembers the selected color for the entire match.
4. User points the camera at the board.
5. AI automatically captures a high-quality frame.
6. AI analyzes the complete board.
7. AI displays:
   - Recommended coin
   - Recommended pocket
   - Striker position
   - Aim line
   - Shot power
   - Success probability
   - Number of currently pocketable coins
8. User places the phone down.
9. User takes the shot.
10. On the next turn, repeat from step 4.

---

# Functional Requirements

## Camera

- Open directly into scan mode.
- Detect when the complete board is visible.
- Reject blurry images.
- Reject partially visible boards.
- Reject heavily obstructed images.
- Automatically capture when the board is stable.

---

## Board Detection

Detect:

- Four board corners
- Playing area
- Four pockets
- Baseline
- Center circle

Generate a normalized coordinate system.

---

## Coin Detection

Recognize:

- Black coins
- White coins
- Queen
- Striker

For every detected object store:

- ID
- Position
- Radius
- Visibility
- Confidence score

---

## Match State

Persist during the match:

- Player color
- Remaining player coins
- Remaining opponent coins
- Queen status
- Current turn
- Previous recommendation
- Shot history

---

## Physics Engine

Simulate:

- Direct shots
- Single rebound shots
- Double rebound shots
- Coin collisions
- Cushion rebounds
- Friction
- Pocket detection

The engine must use the fixed board dimensions and striker size.

---

## Strategy Engine

Generate every legal shot.

Evaluate each candidate using:

- Pocket probability
- Ease of execution
- Future board position
- Queen opportunity
- Cover opportunity
- Risk of foul
- Chance of opening blocked coins
- Opponent advantage

Return only the highest-ranked recommendation.

---

## Recommendation Output

Display:

- Pocketable coins
- Recommended target coin
- Recommended pocket
- Striker placement
- Shot angle
- Shot power
- Success probability

---

## UI

Keep the interface extremely simple.

Top:

Player color.

Middle:

Frozen image of scanned board.

Overlay:

- Green striker path
- Yellow target coin path
- Highlighted target coin
- Highlighted target pocket

Bottom:

Recommendation summary.

No side panels.

No unnecessary statistics.

---

# Offline Requirement

The application must work without internet.

No cloud inference.

No online APIs.

No external processing.

---

# Performance Targets

Analysis time: under one second on iPhone 15 Plus.

Memory usage: under 600 MB.

Smooth user experience.

---

# Technology Stack

Language:
- Swift

UI:
- SwiftUI

Camera:
- AVFoundation

Computer Vision:
- Vision Framework
- OpenCV

Machine Learning:
- Core ML

Rendering:
- SwiftUI overlays

Physics:
- Custom 2D physics engine

Storage:
- SQLite

Logging:
- OSLog

Testing:
- XCTest

---

# Architecture

Presentation Layer

↓

Camera Layer

↓

Vision Layer

↓

Board Model

↓

Physics Engine

↓

Strategy Engine

↓

Recommendation Engine

↓

UI Renderer

Each layer communicates through well-defined interfaces.

---

# Modules

01. Camera Module

02. Board Detection Module

03. Coin Detection Module

04. Perspective Correction Module

05. Board Coordinate System

06. Match State Manager

07. Physics Engine

08. Shot Generator

09. Strategy Engine

10. Recommendation Engine

11. UI Renderer

12. Local Database

13. Configuration

14. Logging

15. Testing

---

# Folder Structure

CarromAICoach/

App/

Camera/

Vision/

Board/

Physics/

Strategy/

Recommendation/

Models/

Database/

Utilities/

Assets/

Tests/

Documentation/

---

# Development Phases

Phase 1
- Project setup
- Architecture
- Coding standards
- CI
- Unit test framework

Phase 2
- Camera
- Board detection
- Perspective correction

Phase 3
- Coin detection
- Object validation
- Coordinate generation

Phase 4
- Physics engine
- Collision simulation
- Rebound simulation

Phase 5
- Strategy engine
- Shot search
- Ranking algorithm

Phase 6
- Recommendation UI
- Overlay rendering
- Match state

Phase 7
- Optimization
- Performance tuning
- Device testing

Phase 8
- Beta testing
- Bug fixing
- Release preparation

---

# Success Criteria

The application is complete when it:

- Detects the board reliably.
- Detects every coin accurately.
- Produces recommendations in under one second.
- Operates entirely offline.
- Runs smoothly on iPhone 15 Plus.
- Provides consistent shot recommendations using the fixed board and striker configuration.

Below is the master prompt for the coding agent.

# Master Prompt for Agentic AI

You are the Lead Software Architect and Principal iOS Engineer responsible for implementing the Carrom AI Coach application.

The complete project specification is stored locally.

Your first task is to read the project specification from the following path:

<ProjectPlanPath>

Replace `<ProjectPlanPath>` with the actual file path before execution.

After reading the specification, perform the following workflow.

1. Read and understand the entire project before writing any code.

2. Produce an implementation roadmap that maps every requirement to concrete software modules.

3. Design the complete architecture before implementation.

4. Create a dependency graph between all modules.

5. Implement the project incrementally.

Never skip directly to full implementation.

Use the following order:

- Project setup
- Architecture
- Data models
- Camera
- Vision
- Board detection
- Coin detection
- Coordinate system
- Physics engine
- Strategy engine
- Recommendation engine
- User interface
- Database
- Testing
- Optimization

For every module:

- Create interfaces first.
- Write production-quality code.
- Write unit tests.
- Verify tests pass.
- Commit only after the module is stable.
- Continue only after validation succeeds.

General rules:

- Swift 6
- SwiftUI
- AVFoundation
- Vision Framework
- Core ML
- SQLite
- OSLog
- XCTest

Requirements:

- Offline only
- No cloud services
- No placeholder implementations unless explicitly marked as TODO
- Strong type safety
- SOLID principles
- Dependency injection
- Modular architecture
- Clear documentation
- Consistent naming
- Comprehensive error handling
- High test coverage
- Performance optimized for iPhone 15 Plus

Maintain a living task list.

After every completed task:

- Update progress.
- Record assumptions.
- Record design decisions.
- Record technical debt.
- Record unresolved issues.

If a requirement is ambiguous:

- Stop.
- Explain the ambiguity.
- Propose options.
- Wait for approval before proceeding.

Never invent functionality that is not present in the project plan.

The final deliverable must be a production-ready Xcode project that builds successfully, passes all automated tests, and matches the project specification.

One additional recommendation: keep the project plan under version control (for example, as `Documentation/ProjectPlan.md`) and have every coding agent treat it as the single source of truth. That makes future changes—such as adding live AR or support for AR glasses—much easier to manage without losing consistency.