<!-- Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---
description: 'Comprehensive technology stack blueprint generator that analyzes codebases to create detailed architectural documentation. Automatically detects technology stacks, programming languages, and implementation patterns across multiple platforms (.NET, Java, JavaScript, React, Python). Generates configurable blueprints with version information, licensing details, usage patterns, coding conventions, and visual diagrams. Provides implementation-ready templates and maintains architectural consistency for guided development.'
agent: 'agent'
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

# Comprehensive Technology Stack Blueprint Generator

## Configuration Variables
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${PROJECT_TYPE="Auto-detect|.NET|Java|JavaScript|React.js|React Native|Angular|Python|Other"} <!-- Primary technology -->
${DEPTH_LEVEL="Basic|Standard|Comprehensive|Implementation-Ready"} <!-- Analysis depth -->
${INCLUDE_VERSIONS=true|false} <!-- Include version information -->
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${INCLUDE_LICENSES=true|false} <!-- Include license information -->
${INCLUDE_DIAGRAMS=true|false} <!-- Generate architecture diagrams -->
${INCLUDE_USAGE_PATTERNS=true|false} <!-- Include code usage patterns -->
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${INCLUDE_CONVENTIONS=true|false} <!-- Document coding conventions -->
${OUTPUT_FORMAT="Markdown|JSON|YAML|HTML"} <!-- Select output format -->
${CATEGORIZATION="Technology Type|Layer|Purpose"} <!-- Organization method -->

<!-- Note 6: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Generated Prompt

"Analyze the codebase and generate a ${DEPTH_LEVEL} technology stack blueprint that thoroughly documents technologies and implementation patterns to facilitate consistent code generation. Use the following approach:

### 1. Technology Identification Phase
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- ${PROJECT_TYPE == "Auto-detect" ? "Scan the codebase for project files, configuration files, and dependencies to determine all technology stacks in use" : "Focus on ${PROJECT_TYPE} technologies"}
- Identify all programming languages by examining file extensions and content
- Analyze configuration files (package.json, .csproj, pom.xml, etc.) to extract dependencies
<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Examine build scripts and pipeline definitions for tooling information
- ${INCLUDE_VERSIONS ? "Extract precise version information from package files and configuration" : "Skip version details"}
- ${INCLUDE_LICENSES ? "Document license information for all dependencies" : ""}

<!-- Note 9: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 2. Core Technologies Analysis

${PROJECT_TYPE == ".NET" || PROJECT_TYPE == "Auto-detect" ? "#### .NET Stack Analysis (if detected)
- Target frameworks and language versions (detect from project files)
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- All NuGet package references with versions and purpose comments
- Project structure and organization patterns
- Configuration approach (appsettings.json, IOptions, etc.)
<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Authentication mechanisms (Identity, JWT, etc.)
- API design patterns (REST, GraphQL, minimal APIs, etc.)
- Data access approaches (EF Core, Dapper, etc.)
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Dependency injection patterns
- Middleware pipeline components" : ""}

${PROJECT_TYPE == "Java" || PROJECT_TYPE == "Auto-detect" ? "#### Java Stack Analysis (if detected)
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- JDK version and core frameworks
- All Maven/Gradle dependencies with versions and purpose
- Package structure organization
<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Spring Boot usage and configurations
- Annotation patterns
- Dependency injection approach
<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Data access technologies (JPA, JDBC, etc.)
- API design (Spring MVC, JAX-RS, etc.)" : ""}

${PROJECT_TYPE == "JavaScript" || PROJECT_TYPE == "Auto-detect" ? "#### JavaScript Stack Analysis (if detected)
<!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- ECMAScript version and transpiler settings
- All npm dependencies categorized by purpose
- Module system (ESM, CommonJS)
<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Build tooling (webpack, Vite, etc.) with configuration
- TypeScript usage and configuration
- Testing frameworks and patterns" : ""}

<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${PROJECT_TYPE == "React.js" || PROJECT_TYPE == "Auto-detect" ? "#### React Analysis (if detected)
- React version and key patterns (hooks vs class components)
- State management approach (Context, Redux, Zustand, etc.)
<!-- Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Component library usage (Material-UI, Chakra, etc.)
- Routing implementation
- Form handling strategies
<!-- Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- API integration patterns
- Testing approach for components" : ""}

${PROJECT_TYPE == "Python" || PROJECT_TYPE == "Auto-detect" ? "#### Python Analysis (if detected)
<!-- Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Python version and key language features used
- Package dependencies and virtual environment setup
- Web framework details (Django, Flask, FastAPI)
<!-- Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- ORM usage patterns
- Project structure organization
- API design patterns" : ""}

<!-- Note 23: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 3. Implementation Patterns & Conventions
${INCLUDE_CONVENTIONS ? 
"Document coding conventions and patterns for each technology area:

<!-- Note 24: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### Naming Conventions
- Class/type naming patterns
- Method/function naming patterns
<!-- Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Variable naming conventions
- File naming and organization conventions
- Interface/abstract class patterns

<!-- Note 26: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### Code Organization
- File structure and organization
- Folder hierarchy patterns
<!-- Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Component/module boundaries
- Code separation and responsibility patterns

#### Common Patterns
<!-- Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Error handling approaches
- Logging patterns
- Configuration access
<!-- Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Authentication/authorization implementation
- Validation strategies
- Testing patterns" : ""}

<!-- Note 30: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 4. Usage Examples
${INCLUDE_USAGE_PATTERNS ? 
"Extract representative code examples showing standard implementation patterns:

<!-- Note 31: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### API Implementation Examples
- Standard controller/endpoint implementation
- Request DTO pattern
<!-- Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Response formatting
- Validation approach
- Error handling

<!-- Note 33: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### Data Access Examples
- Repository pattern implementation
- Entity/model definitions
<!-- Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Query patterns
- Transaction handling

#### Service Layer Examples
<!-- Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Service class implementation
- Business logic organization
- Cross-cutting concerns integration
<!-- Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Dependency injection usage

#### UI Component Examples (if applicable)
- Component structure
<!-- Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- State management pattern
- Event handling
- API integration pattern" : ""}

<!-- Note 38: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 5. Technology Stack Map
${DEPTH_LEVEL == "Comprehensive" || DEPTH_LEVEL == "Implementation-Ready" ? 
"Create a comprehensive technology map including:

<!-- Note 39: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### Core Framework Usage
- Primary frameworks and their specific usage in the project
- Framework-specific configurations and customizations
<!-- Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Extension points and customizations

#### Integration Points
- How different technology components integrate
<!-- Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Authentication flow between components
- Data flow between frontend and backend
- Third-party service integration patterns

<!-- Note 42: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### Development Tooling
- IDE settings and conventions
- Code analysis tools
<!-- Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Linters and formatters with configuration
- Build and deployment pipeline
- Testing frameworks and approaches

<!-- Note 44: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### Infrastructure
- Deployment environment details
- Container technologies
<!-- Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Cloud services utilized
- Monitoring and logging infrastructure" : ""}

### 6. Technology-Specific Implementation Details

<!-- Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
${PROJECT_TYPE == ".NET" || PROJECT_TYPE == "Auto-detect" ? 
"#### .NET Implementation Details (if detected)
- **Dependency Injection Pattern**:
  <!-- Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Service registration approach (Scoped/Singleton/Transient patterns)
  - Configuration binding patterns
  
- **Controller Patterns**:
  <!-- Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Base controller usage
  - Action result types and patterns
  - Route attribute conventions
  <!-- Note 49: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Filter usage (authorization, validation, etc.)
  
- **Data Access Patterns**:
  - ORM configuration and usage
  <!-- Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Entity configuration approach
  - Relationship definitions
  - Query patterns and optimization approaches
  
<!-- Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **API Design Patterns** (if used):
  - Endpoint organization
  - Parameter binding approaches
  <!-- Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Response type handling
  
- **Language Features Used**:
  - Detect specific language features from code
  <!-- Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Identify common patterns and idioms
  - Note any specific version-dependent features" : ""}

${PROJECT_TYPE == "React.js" || PROJECT_TYPE == "Auto-detect" ? 
<!-- Note 54: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
"#### React Implementation Details (if detected)
- **Component Structure**:
  - Function vs class components
  <!-- Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Props interface definitions
  - Component composition patterns
  
- **Hook Usage Patterns**:
  <!-- Note 56: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Custom hook implementation style
  - useState patterns
  - useEffect cleanup approaches
  <!-- Note 57: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Context usage patterns
  
- **State Management**:
  - Local vs global state decisions
  <!-- Note 58: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - State management library patterns
  - Store configuration
  - Selector patterns
  
<!-- Note 59: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Styling Approach**:
  - CSS methodology (CSS modules, styled-components, etc.)
  - Theme implementation
  <!-- Note 60: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  - Responsive design patterns" : ""}

### 7. Blueprint for New Code Implementation
${DEPTH_LEVEL == "Implementation-Ready" ? 
<!-- Note 61: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
"Based on the analysis, provide a detailed blueprint for implementing new features:

- **File/Class Templates**: Standard structure for common component types
- **Code Snippets**: Ready-to-use code patterns for common operations
- **Implementation Checklist**: Standard steps for implementing features end-to-end
- **Integration Points**: How to connect new code with existing systems
- **Testing Requirements**: Standard test patterns for different component types
- **Documentation Requirements**: Standard doc patterns for new features" : ""}

${INCLUDE_DIAGRAMS ? 
"### 8. Technology Relationship Diagrams
- **Stack Diagram**: Visual representation of the complete technology stack
- **Dependency Flow**: How different technologies interact
- **Component Relationships**: How major components depend on each other
- **Data Flow**: How data flows through the technology stack" : ""}

### ${INCLUDE_DIAGRAMS ? "9" : "8"}. Technology Decision Context
- Document apparent reasons for technology choices
- Note any legacy or deprecated technologies marked for replacement
- Identify technology constraints and boundaries
- Document technology upgrade paths and compatibility considerations

Format the output as ${OUTPUT_FORMAT} and categorize technologies by ${CATEGORIZATION}.

Save the output as 'Technology_Stack_Blueprint.${OUTPUT_FORMAT == "Markdown" ? "md" : OUTPUT_FORMAT.toLowerCase()}'
"