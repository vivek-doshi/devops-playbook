<!-- Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---
description: 'Comprehensive project architecture blueprint generator that analyzes codebases to create detailed architectural documentation. Automatically detects technology stacks and architectural patterns, generates visual diagrams, documents implementation patterns, and provides extensible blueprints for maintaining architectural consistency and guiding new development.'
agent: 'agent'
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

# Comprehensive Project Architecture Blueprint Generator

## Configuration Variables
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${PROJECT_TYPE="Auto-detect|.NET|Java|React|Angular|Python|Node.js|Flutter|Other"} <!-- Primary technology -->
${ARCHITECTURE_PATTERN="Auto-detect|Clean Architecture|Microservices|Layered|MVVM|MVC|Hexagonal|Event-Driven|Serverless|Monolithic|Other"} <!-- Primary architectural pattern -->
${DIAGRAM_TYPE="C4|UML|Flow|Component|None"} <!-- Architecture diagram type -->
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${DETAIL_LEVEL="High-level|Detailed|Comprehensive|Implementation-Ready"} <!-- Level of detail to include -->
${INCLUDES_CODE_EXAMPLES=true|false} <!-- Include sample code to illustrate patterns -->
${INCLUDES_IMPLEMENTATION_PATTERNS=true|false} <!-- Include detailed implementation patterns -->
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${INCLUDES_DECISION_RECORDS=true|false} <!-- Include architectural decision records -->
${FOCUS_ON_EXTENSIBILITY=true|false} <!-- Emphasize extension points and patterns -->

## Generated Prompt

<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
"Create a comprehensive 'Project_Architecture_Blueprint.md' document that thoroughly analyzes the architectural patterns in the codebase to serve as a definitive reference for maintaining architectural consistency. Use the following approach:

### 1. Architecture Detection and Analysis
- ${PROJECT_TYPE == "Auto-detect" ? "Analyze the project structure to identify all technology stacks and frameworks in use by examining:
  <!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Project and configuration files
  - Package dependencies and import statements
  - Framework-specific patterns and conventions
  <!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Build and deployment configurations" : "Focus on ${PROJECT_TYPE} specific patterns and practices"}
  
- ${ARCHITECTURE_PATTERN == "Auto-detect" ? "Determine the architectural pattern(s) by analyzing:
  - Folder organization and namespacing
  <!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Dependency flow and component boundaries
  - Interface segregation and abstraction patterns
  - Communication mechanisms between components" : "Document how the ${ARCHITECTURE_PATTERN} architecture is implemented"}

<!-- Note 10: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 2. Architectural Overview
- Provide a clear, concise explanation of the overall architectural approach
- Document the guiding principles evident in the architectural choices
<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Identify architectural boundaries and how they're enforced
- Note any hybrid architectural patterns or adaptations of standard patterns

### 3. Architecture Visualization
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${DIAGRAM_TYPE != "None" ? `Create ${DIAGRAM_TYPE} diagrams at multiple levels of abstraction:
- High-level architectural overview showing major subsystems
- Component interaction diagrams showing relationships and dependencies
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Data flow diagrams showing how information moves through the system
- Ensure diagrams accurately reflect the actual implementation, not theoretical patterns` : "Describe the component relationships based on actual code dependencies, providing clear textual explanations of:
- Subsystem organization and boundaries
<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Dependency directions and component interactions
- Data flow and process sequences"}

### 4. Core Architectural Components
<!-- Note 15: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting. -->
For each architectural component discovered in the codebase:

- **Purpose and Responsibility**:
  - Primary function within the architecture
  <!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Business domains or technical concerns addressed
  - Boundaries and scope limitations

- **Internal Structure**:
  <!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Organization of classes/modules within the component
  - Key abstractions and their implementations
  - Design patterns utilized

<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Interaction Patterns**:
  - How the component communicates with others
  - Interfaces exposed and consumed
  <!-- Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Dependency injection patterns
  - Event publishing/subscription mechanisms

- **Evolution Patterns**:
  <!-- Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - How the component can be extended
  - Variation points and plugin mechanisms
  - Configuration and customization approaches

<!-- Note 21: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 5. Architectural Layers and Dependencies
- Map the layer structure as implemented in the codebase
- Document the dependency rules between layers
<!-- Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Identify abstraction mechanisms that enable layer separation
- Note any circular dependencies or layer violations
- Document dependency injection patterns used to maintain separation

<!-- Note 23: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 6. Data Architecture
- Document domain model structure and organization
- Map entity relationships and aggregation patterns
<!-- Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Identify data access patterns (repositories, data mappers, etc.)
- Document data transformation and mapping approaches
- Note caching strategies and implementations
<!-- Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Document data validation patterns

### 7. Cross-Cutting Concerns Implementation
Document implementation patterns for cross-cutting concerns:

<!-- Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Authentication & Authorization**:
  - Security model implementation
  - Permission enforcement patterns
  <!-- Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Identity management approach
  - Security boundary patterns

- **Error Handling & Resilience**:
  <!-- Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Exception handling patterns
  - Retry and circuit breaker implementations
  - Fallback and graceful degradation strategies
  <!-- Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Error reporting and monitoring approaches

- **Logging & Monitoring**:
  - Instrumentation patterns
  <!-- Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Observability implementation
  - Diagnostic information flow
  - Performance monitoring approach

<!-- Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Validation**:
  - Input validation strategies
  - Business rule validation implementation
  <!-- Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Validation responsibility distribution
  - Error reporting patterns

- **Configuration Management**:
  <!-- Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Configuration source patterns
  - Environment-specific configuration strategies
  - Secret management approach
  <!-- Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Feature flag implementation

### 8. Service Communication Patterns
- Document service boundary definitions
<!-- Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Identify communication protocols and formats
- Map synchronous vs. asynchronous communication patterns
- Document API versioning strategies
<!-- Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Identify service discovery mechanisms
- Note resilience patterns in service communication

### 9. Technology-Specific Architectural Patterns
<!-- Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${PROJECT_TYPE == "Auto-detect" ? "For each detected technology stack, document specific architectural patterns:" : `Document ${PROJECT_TYPE}-specific architectural patterns:`}

${(PROJECT_TYPE == ".NET" || PROJECT_TYPE == "Auto-detect") ? 
"#### .NET Architectural Patterns (if detected)
<!-- Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Host and application model implementation
- Middleware pipeline organization
- Framework service integration patterns
<!-- Note 39: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- ORM and data access approaches
- API implementation patterns (controllers, minimal APIs, etc.)
- Dependency injection container configuration" : ""}

<!-- Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${(PROJECT_TYPE == "Java" || PROJECT_TYPE == "Auto-detect") ? 
"#### Java Architectural Patterns (if detected)
- Application container and bootstrap process
<!-- Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Dependency injection framework usage (Spring, CDI, etc.)
- AOP implementation patterns
- Transaction boundary management
<!-- Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- ORM configuration and usage patterns
- Service implementation patterns" : ""}

${(PROJECT_TYPE == "React" || PROJECT_TYPE == "Auto-detect") ? 
<!-- Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
"#### React Architectural Patterns (if detected)
- Component composition and reuse strategies
- State management architecture
<!-- Note 44: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Side effect handling patterns
- Routing and navigation approach
- Data fetching and caching patterns
<!-- Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Rendering optimization strategies" : ""}

${(PROJECT_TYPE == "Angular" || PROJECT_TYPE == "Auto-detect") ? 
"#### Angular Architectural Patterns (if detected)
<!-- Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Module organization strategy
- Component hierarchy design
- Service and dependency injection patterns
<!-- Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- State management approach
- Reactive programming patterns
- Route guard implementation" : ""}

<!-- Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${(PROJECT_TYPE == "Python" || PROJECT_TYPE == "Auto-detect") ? 
"#### Python Architectural Patterns (if detected)
- Module organization approach
<!-- Note 49: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Dependency management strategy
- OOP vs. functional implementation patterns
- Framework integration patterns
<!-- Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Asynchronous programming approach" : ""}

### 10. Implementation Patterns
${INCLUDES_IMPLEMENTATION_PATTERNS ? 
<!-- Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
"Document concrete implementation patterns for key architectural components:

- **Interface Design Patterns**:
  - Interface segregation approaches
  <!-- Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Abstraction level decisions
  - Generic vs. specific interface patterns
  - Default implementation patterns

<!-- Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Service Implementation Patterns**:
  - Service lifetime management
  - Service composition patterns
  <!-- Note 54: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Operation implementation templates
  - Error handling within services

- **Repository Implementation Patterns**:
  <!-- Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Query pattern implementations
  - Transaction management
  - Concurrency handling
  <!-- Note 56: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Bulk operation patterns

- **Controller/API Implementation Patterns**:
  - Request handling patterns
  <!-- Note 57: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Response formatting approaches
  - Parameter validation
  - API versioning implementation

<!-- Note 58: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Domain Model Implementation**:
  - Entity implementation patterns
  - Value object patterns
  <!-- Note 59: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Domain event implementation
  - Business rule enforcement" : "Mention that detailed implementation patterns vary across the codebase."}

### 11. Testing Architecture
<!-- Note 60: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Document testing strategies aligned with the architecture
- Identify test boundary patterns (unit, integration, system)
- Map test doubles and mocking approaches
<!-- Note 61: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Document test data strategies
- Note testing tools and frameworks integration

### 12. Deployment Architecture
<!-- Note 62: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Document deployment topology derived from configuration
- Identify environment-specific architectural adaptations
- Map runtime dependency resolution patterns
<!-- Note 63: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Document configuration management across environments
- Identify containerization and orchestration approaches
- Note cloud service integration patterns

<!-- Note 64: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 13. Extension and Evolution Patterns
${FOCUS_ON_EXTENSIBILITY ? 
"Provide detailed guidance for extending the architecture:

<!-- Note 65: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Feature Addition Patterns**:
  - How to add new features while preserving architectural integrity
  - Where to place new components by type
  <!-- Note 66: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Dependency introduction guidelines
  - Configuration extension patterns

- **Modification Patterns**:
  <!-- Note 67: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - How to safely modify existing components
  - Strategies for maintaining backward compatibility
  - Deprecation patterns
  <!-- Note 68: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Migration approaches

- **Integration Patterns**:
  - How to integrate new external systems
  <!-- Note 69: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Adapter implementation patterns
  - Anti-corruption layer patterns
  - Service facade implementation" : "Document key extension points in the architecture."}

<!-- Note 70: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${INCLUDES_CODE_EXAMPLES ? 
"### 14. Architectural Pattern Examples
Extract representative code examples that illustrate key architectural patterns:

<!-- Note 71: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Layer Separation Examples**:
  - Interface definition and implementation separation
  - Cross-layer communication patterns
  <!-- Note 72: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Dependency injection examples

- **Component Communication Examples**:
  - Service invocation patterns
  <!-- Note 73: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Event publication and handling
  - Message passing implementation

- **Extension Point Examples**:
  <!-- Note 74: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Plugin registration and discovery
  - Extension interface implementations
  - Configuration-driven extension patterns

<!-- Note 75: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Include enough context with each example to show the pattern clearly, but keep examples concise and focused on architectural concepts." : ""}

${INCLUDES_DECISION_RECORDS ? 
"### 15. Architectural Decision Records
<!-- Note 76: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Document key architectural decisions evident in the codebase:

- **Architectural Style Decisions**:
  - Why the current architectural pattern was chosen
  <!-- Note 77: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Alternatives considered (based on code evolution)
  - Constraints that influenced the decision

- **Technology Selection Decisions**:
  <!-- Note 78: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Key technology choices and their architectural impact
  - Framework selection rationales
  - Custom vs. off-the-shelf component decisions

<!-- Note 79: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Implementation Approach Decisions**:
  - Specific implementation patterns chosen
  - Standard pattern adaptations
  <!-- Note 80: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Performance vs. maintainability tradeoffs

For each decision, note:
- Context that made the decision necessary
<!-- Note 81: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Factors considered in making the decision
- Resulting consequences (positive and negative)
- Future flexibility or limitations introduced" : ""}

### ${INCLUDES_DECISION_RECORDS ? "16" : INCLUDES_CODE_EXAMPLES ? "15" : "14"}. Architecture Governance
- Document how architectural consistency is maintained
- Identify automated checks for architectural compliance
- Note architectural review processes evident in the codebase
- Document architectural documentation practices

### ${INCLUDES_DECISION_RECORDS ? "17" : INCLUDES_CODE_EXAMPLES ? "16" : "15"}. Blueprint for New Development
Create a clear architectural guide for implementing new features:

- **Development Workflow**:
  - Starting points for different feature types
  - Component creation sequence
  - Integration steps with existing architecture
  - Testing approach by architectural layer

- **Implementation Templates**:
  - Base class/interface templates for key architectural components
  - Standard file organization for new components
  - Dependency declaration patterns
  - Documentation requirements

- **Common Pitfalls**:
  - Architecture violations to avoid
  - Common architectural mistakes
  - Performance considerations
  - Testing blind spots

Include information about when this blueprint was generated and recommendations for keeping it updated as the architecture evolves."