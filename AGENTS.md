# AGENTS.md

This document defines the autonomous agents responsible for managing SwiftPM dependencies, build setup, and modular integration in the `SwiftUI-UDF` package, particularly in Xcode-based workflows.

## Agent: `SPMResolverAgent`

**Purpose**:  
Resolves and preloads Swift Package Manager (SPM) dependencies during workspace initialization.

**Responsibilities**:
- Triggered during `xcodebuild` or IDE startup.
- Runs `swift package resolve` to fetch locked dependencies.
- Detects and resolves version mismatches using `Package.resolved`.
- Logs resolution conflicts or missing Git repositories.

**Dependencies**:
- `Package.swift`
- `Package.resolved`
- `.xcodeproj` or `.xcworkspace`

---

## Agent: `BuildWarmupAgent`

**Purpose**:  
Speeds up initial Xcode indexing by precompiling frequently used modules.

**Responsibilities**:
- Invoked via CLI (e.g., `xcodebuild -resolvePackageDependencies`).
- Ensures modules like `Combine`, `SwiftUI`, and `Concurrency` are warmed up.
- Uses `.build/checkouts` and `.build/repositories` as persistent cache layers.

**Dependencies**:
- `DerivedData` paths
- SPM cache directories

---

## Agent: `DependencyValidatorAgent`

**Purpose**:  
Validates that all Swift packages conform to semantic versioning and are correctly committed.

**Responsibilities**:
- Checks for uncommitted or untagged dependencies.
- Compares `Package.resolved` with upstream package manifests.
- Emits warnings for mismatched versions or unpublished forks.

**Tooling**:
- Runs optionally via `pre-action` script in Xcode build phases.

---

## Agent: `XcodeIntegrationAgent`

**Purpose**:  
Ensures seamless integration of SwiftPM packages with Xcode’s build and runtime systems.

**Responsibilities**:
- Verifies that `Package.swift` is recognized in `.xcworkspace`.
- Monitors changes in dependency graph for triggering re-indexing.
- Helps modularize components for easier IDE inspection.

**Integration Points**:
- `Xcode Scheme`
- `Xcode Build Settings`

---

## Agent Boot Sequence

1. `SPMResolverAgent`
2. `BuildWarmupAgent`
3. `DependencyValidatorAgent`
4. `XcodeIntegrationAgent`

---
