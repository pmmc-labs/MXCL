# MXCL Project Plan

This document organizes all TODO items from TODO.md and code comments into a structured implementation plan.

## 1. Core Type System & Terms

### 1.1 Term Cleanup (Priority: High)
**Status**: Not Started
**Files**: `lib/MXCL/Term/*.pm`, `lib/MXCL/Allocator/Terms.pm`

- [ ] Remove all Tuple references (use immutable Arrays instead)
- [ ] Remove all Pair references (no longer needed)
- [ ] Create a Hash term type
- [ ] Standardize on `->unbox` name for all unboxing methods across all term types

**Rationale**: Clean up legacy type system before building new features on top.

---

## 2. Traits & Slots System

### 2.1 Slot Interface Improvements (Priority: Medium)
**Status**: Not Started
**Files**: `lib/MXCL/Term/Trait.pm`, `lib/MXCL/Allocator/Traits.pm`

- [ ] Turn Slot interface into Option-like type
  - [ ] Add `get()` method
  - [ ] Add `get_or_else()` method
- [ ] Make Absent, Required, Excluded singletons (Allocator/Traits.pm:30)
- [ ] Auto-wrap non-Slot bindings in `Defined()` during Trait construction (Allocator/Traits.pm:18)
  - This would simplify trait construction

**Files**:
- `lib/MXCL/Allocator/Traits.pm:18` (NOTE)
- `lib/MXCL/Allocator/Traits.pm:30` (TODO)

### 2.2 Trait Composition (Priority: High)
**Status**: Partially Implemented
**Files**: `lib/MXCL/Allocator/Traits.pm`, `lib/MXCL/Term/Trait.pm`

Current limitations (TODO.md + code):
- Only supports union operation
- Doesn't handle Conflict or Alias properly
- Excluded slot behavior seems odd

**Tasks**:
- [ ] Add difference operation for trait composition
- [ ] Fix `MergeSlots()` to handle Conflict slots (Allocator/Traits.pm:45)
- [ ] Fix `MergeSlots()` to handle Alias slots (Allocator/Traits.pm:45)
- [ ] Review Excluded slot behavior in merging (Allocator/Traits.pm:45)
- [ ] Fix `MergeTraits()` to turn missing keys into Absent slots (Allocator/Traits.pm:75)
- [ ] Make `lookup()` return Absent if nothing found (currently doesn't)
- [ ] Add methods to check trait resolution state (Term/Trait.pm:12)
  - `is_resolved()`
  - `has_requirements()`
  - `has_conflicts()`
- [ ] Add conflict resolution methods (Term/Trait.pm:12)

**Files**:
- `lib/MXCL/Allocator/Traits.pm:45` (TODO)
- `lib/MXCL/Allocator/Traits.pm:75` (TODO)
- `lib/MXCL/Term/Trait.pm:12` (TODO)

### 2.3 Trait Provenance Tracking (Priority: Low)
**Status**: Not Started

- [ ] Flatten list of all traits included (recursively)
- [ ] Do NOT include provenance in the hash
- [ ] Figure out details for Alias/Exclude handling in provenance

**Rationale**: Debugging and introspection support.

### 2.4 JIT Slot Optimization (Priority: Future)
**Status**: Design Phase

- [ ] Design: Use Slots as JIT replacement points
- [ ] Replace nodes with equivalent compiled nodes
- [ ] Explore zk proofs for equivalence verification

**Rationale**: Performance optimization hook for future work.

---

## 3. Scope System

### 3.1 Scope Composition Refinement (Priority: High)
**Status**: Design Phase

**Current Issues**:
- Scope composition logic is rough
- Missing Required/Absent/Conflict/Excluded/Alias handling

**Design Tasks**:
- [ ] Add Required methods for parameters
- [ ] Add Required methods for recursive calls
- [ ] Traverse AST to find free variables
  - [ ] Only add recursive name if actually used
  - [ ] Only include Defined values that are needed
- [ ] Decide on Conflict handling strategy:
  - Option A: Conflicts act as shadows (current thinking)
  - Option B: Exclude params/recursive names from parent before composition
- [ ] Verify: No Absent methods should exist at this point
- [ ] Clarify: Does Alias make sense in this context?

### 3.2 Machine Scope Handling (Priority: High)
**Status**: Not Started
**Blocks**: Full trait/scope integration

**Tasks**: Make Machine handle non-Defined slot types in composed Scopes:
- [ ] Handle Conflict slots
  - Both values present
  - Send all reads to the right one
  - Keeps trait composition clean
- [ ] Handle Absent slots
  - Should throw an error
- [ ] Handle Required slots
  - Unsatisfied requirements are bad
- [ ] Handle Excluded slots
- [ ] Handle Alias slots
  - May not make sense here
  - Might already be resolved during lookup

---

## 4. Arena & Memory Management

### 4.1 Arena Improvements (Priority: Medium)
**Status**: Partially Implemented
**Files**: `lib/MXCL/Arena.pm`

- [ ] Add method to walk the hashes
- [ ] Fix generation tracking data (Arena.pm:28)
  - Currently repurposed from old stats collection
  - Works but needs proper implementation
- [ ] Improve hash generation robustness (Arena.pm:100)
  - Current implementation is fragile and opaque
  - Need better error catching for hash generation issues

**Files**:
- `lib/MXCL/Arena.pm:28` (NOTE)
- `lib/MXCL/Arena.pm:100` (FIXME)

---

## 5. Machine & Execution

### 5.1 Applicative Context Passing (Priority: Medium)
**Status**: Not Started

- [ ] Pass ctx variable as first arg to Applicatives
  - Allows allocation within applicatives
  - Lifted native subs should never see it

### 5.2 Stack Management (Priority: High)
**Status**: Design Phase
**Blocks**: Proper expression sequencing

**Issues**:
- Expression results leak onto next expression's stack
- Affects both Machine.pm and Runtime.pm `do` builtin

**Tasks**:
- [ ] Investigate Eval::TOS purpose (Machine.pm:22)
  - Can't find why/where it was added
- [ ] Design Drop-Stack/End-Statement kontinue (Machine.pm:22, Runtime.pm:122)
  - Prevents results from ending up on next expression's stack
  - Must preserve last value for return
- [ ] Implement stack drop kontinue
- [ ] Update `do` builtin to use it (Runtime.pm:122)
- [ ] Update `Machine->run()` to prevent stack leakage (Machine.pm:22)

**Files**:
- `lib/MXCL/Machine.pm:22` (FIXME)
- `lib/MXCL/Machine.pm:51` (NOTE - explains Return kontinue env/stack threading)
- `lib/MXCL/Runtime.pm:122` (FIXME)

### 5.3 Kontinue Refactoring (Priority: Low)
**Status**: Not Started
**Files**: `lib/MXCL/Allocator/Kontinues.pm`

- [ ] Replace Define/Mutate kontinues (Kontinues.pm:244)
- [ ] Turn Return into explicit stack operations (Kontinues.pm:255)

**Files**:
- `lib/MXCL/Allocator/Kontinues.pm:244` (TODO)
- `lib/MXCL/Allocator/Kontinues.pm:255` (TODO)

---

## 6. Control Flow & Scoping Kontinues

### 6.1 Exception Handling (Priority: High)
**Status**: Stub Implemented, Not Functional
**Files**: `lib/MXCL/Term/Kontinue/Throw.pm`, `lib/MXCL/Term/Kontinue/Catch.pm`, `lib/MXCL/Allocator/Kontinues.pm`

**Current State**:
- Throw and Catch kontinue classes exist as stubs
- Design notes exist in Allocator/Kontinues.pm:220-232
- No Machine.pm implementation yet

**Design** (from Kontinues.pm):
- **Throw**: Unwinds the queue
  - Collects any Context::Leave kontinuations encountered
  - Stops when a Catch is found
  - Passes exception to Catch via stack
  - Enqueues the Catch and any collected Leave kontinues
- **Catch**: Handles exception
  - If top of stack is an exception: apply handler with exception on its stack
  - Otherwise: just return top of stack

**Tasks**:
- [ ] Implement Throw unwinding logic in Machine.pm
  - [ ] Queue unwinding until Catch found
  - [ ] Collect Context::Leave (or future Scope::Leave) kontinues
  - [ ] Pass exception via stack
- [ ] Implement Catch handling logic in Machine.pm
  - [ ] Check for exception on stack
  - [ ] Apply handler if exception present
  - [ ] Pass through if no exception
- [ ] Add tests for basic exception handling
- [ ] Add tests for exception + deferred cleanup interaction

**Files**:
- `lib/MXCL/Allocator/Kontinues.pm:220-232` (Design notes)
- `lib/MXCL/Term/Kontinue/Throw.pm` (Stub)
- `lib/MXCL/Term/Kontinue/Catch.pm` (Stub)

### 6.2 Scope/Expression Entry & Exit (Priority: High)
**Status**: Design Phase - Requires Architecture Decision
**Files**: `lib/MXCL/Term/Kontinue/Context/Enter.pm`, `lib/MXCL/Term/Kontinue/Context/Leave.pm`

**Current State**:
- Context::Enter and Context::Leave exist but not fully implemented
- Need to be renamed to Scope::Enter/Leave
- Design questions remain about responsibilities and interaction with Return

**Design Questions**:
1. **Naming & Semantics**: Context::Enter/Leave → Scope::Enter/Leave
2. **Relationship with Return kontinue**:
   - Return currently resets environment (Machine.pm:205)
   - How should Scope::Enter/Leave interact with this?
   - Should Scope::Enter/Leave handle environment reset instead?
3. **Connection to Stack Management**:
   - Stack leakage issue (5.2) may relate to scope boundaries
   - Should scope kontinues manage stack cleanup?
4. **Two-Level Design Possibility**:
   - **Scope::Enter/Leave**: Environment/binding management
   - **Expr::Enter/Leave**: Expression-level stack management
   - Would this cleanly separate concerns?

**Current Design** (from Kontinues.pm:206-214):
- **Context::Enter**:
  - Paired with a Leave kontinue
  - Returns all values from stack
  - Defines local `defer` which pushes to paired Leave
- **Context::Leave**:
  - Runs all deferred calls
  - Returns all values from stack

**Proposed Tasks**:
- [ ] **Design Decision**: Clarify responsibilities
  - [ ] What handles environment reset? (Return vs Scope::Enter/Leave)
  - [ ] What handles stack cleanup? (Expr kontinues vs Scope kontinues?)
  - [ ] Should we have both Scope::* and Expr::* pairs?
- [ ] **Rename**: Context::Enter/Leave → Scope::Enter/Leave
- [ ] **Implement Scope::Enter/Leave**:
  - [ ] Define exact semantics for environment management
  - [ ] Implement `defer` mechanism
  - [ ] Handle interaction with Return kontinue
  - [ ] Add Machine.pm support
- [ ] **Consider Expr::Enter/Leave** (if needed):
  - [ ] Design expression-level stack boundaries
  - [ ] Implement stack cleanup semantics
  - [ ] Coordinate with stack management fixes (5.2)
- [ ] **Integration**:
  - [ ] Update Throw to collect Scope::Leave (not Context::Leave)
  - [ ] Ensure proper unwinding during exceptions
  - [ ] Add tests for scope + exception interaction

**Files**:
- `lib/MXCL/Term/Kontinue/Context/Enter.pm` (Partial implementation)
- `lib/MXCL/Term/Kontinue/Context/Leave.pm` (Partial implementation)
- `lib/MXCL/Allocator/Kontinues.pm:206-214` (Design notes)
- `lib/MXCL/Machine.pm:205` (Return/environment reset)

**Intersection with Other Work**:
- **Stack Management (5.2)**: May be solved or simplified by Expr::Enter/Leave
- **Exception Handling (6.1)**: Throw must collect Scope::Leave kontinues
- **Return Kontinue**: Semantics may change based on Scope::Enter/Leave design

---

## 7. Context System

### 7.1 Context Improvements (Priority: Medium)
**Status**: Design Phase

- [ ] Add Builder to construct Kontinue queues
- [ ] Consider adding queue into Context
  - Single serialization point
  - Centralized serialization logic
  - Could still allow separate serialization
- [ ] Think about commit semantics

**Rationale**: Better serialization story for continuations.

---

## 8. Natives & Builtins

### 8.1 Signature Specification (Priority: Medium)
**Status**: Not Started
**Files**: `lib/MXCL/Runtime.pm`

- [ ] Fix sloppy varargs for `do` builtin (Runtime.pm:54)
- [ ] Design signature specification system
- [ ] Add type predicates for Native::* types (Runtime.pm:54)
- [ ] Add type predicates for Kontinue::* types (Runtime.pm:54)
- [ ] Ponder `type-of?` implementation:
  - Should it accept Sym/Tag and check against it?
  - Should types be registered in base scope as singleton Terms?

**Files**:
- `lib/MXCL/Runtime.pm:54` (TODO)

---

## 9. Parser & Compiler

### 9.1 Parser Updates (Priority: High)
**Status**: Not Started
**Blocks**: Array/Hash literal support

- [ ] Strip comments from source
- [ ] Revise sugar syntax:
  - `@[]` becomes `+[]`
  - `%{}` becomes `+{}`
  - `{}` stays as is (blocks)
  - Remove tuple parsing
- [ ] Add generation metadata to tokens/compounds
  - Coordinate with Arena generation tracking

### 9.2 Compiler Updates (Priority: High)
**Status**: Blocked by Parser
**Files**: `lib/MXCL/Compiler.pm`

- [ ] Handle parser syntax changes
- [ ] Don't expand arrays - return Array term (Compiler.pm:90)
  - Similar to how Lists work currently

**Files**:
- `lib/MXCL/Compiler.pm:90` (TODO)

---

## 10. Tooling & Developer Experience

### 10.1 Debugger Cleanup (Priority: Low)
**Status**: Working but has dependency issue
**Files**: `lib/MXCL/Debugger.pm`

- [ ] Remove P5::TUI::Table dependency (Debugger.pm:9)
  - Consider alternatives or inline the functionality

**Files**:
- `lib/MXCL/Debugger.pm:9` (FIXME)

---

## Implementation Phases

### Phase 1: Foundation (Current Priority)
**Goal**: Clean up type system and fix critical execution issues

1. Term Cleanup (1.1)
2. Stack Management (5.2) - **CRITICAL**
3. Scope/Expression Entry & Exit Design (6.2) - **CRITICAL DESIGN DECISION**
4. Parser/Compiler Updates (9.1, 9.2)

### Phase 2: Control Flow & Scopes
**Goal**: Implement control flow and complete scope system

1. Scope::Enter/Leave Implementation (6.2)
2. Exception Handling (6.1) - Throw/Catch
3. Trait Composition (2.2)
4. Slot Interface (2.1)
5. Scope Composition (3.1)
6. Machine Scope Handling (3.2)

### Phase 3: Polish & Optimization
**Goal**: Improve developer experience and performance

1. Signature Specification (8.1)
2. Arena Improvements (4.1)
3. Context Improvements (7.1)
4. Applicative Context Passing (5.1)

### Phase 4: Future Work
**Goal**: Advanced features and optimizations

1. Trait Provenance (2.3)
2. JIT Slots (2.4)
3. Kontinue Refactoring (5.3)
4. Debugger Cleanup (10.1)

---

## Critical Path

The following items block significant functionality and require immediate attention:

1. **Scope/Expression Entry & Exit Design (6.2)** - **CRITICAL DESIGN DECISION**
   - Must resolve before implementing stack management fixes
   - Affects Return kontinue semantics
   - May solve or simplify stack leakage issues
   - Determines whether we need Scope::* and Expr::* pairs

2. **Stack Management (5.2)** - Expression sequencing currently broken
   - Blocked by or intersects with 6.2 design decisions
   - Critical for correct expression evaluation

3. **Exception Handling (6.1)** - Throw/Catch implementation
   - Depends on Scope::Enter/Leave design (renamed from Context::Enter/Leave)
   - Needed for proper error handling and unwinding

4. **Parser/Compiler Updates (9.1, 9.2)** - Needed for array/hash literals
   - Required for complete type system

5. **Trait Composition (2.2)** - Core feature incomplete
   - Blocks advanced scope composition

6. **Machine Scope Handling (3.2)** - Needed for full trait/scope integration
   - Depends on trait composition completion

---

## Notes on Conventions

Throughout the codebase, TODO markers use this convention:
- `TODO:` - Feature to implement
- `FIXME:` - Bug or issue to fix
- `NOTE:` - Design consideration or explanation
- `XXX:` - (None found in current code)

All line number references are current as of 2026-02-14.
