## Chosen Approach
Implement FileRewriter with hexagonal architecture, using pure functions for content construction and adapters for I/O, ensuring atomic writes, backups, and strict adherence to coding standards.

## Rationale
- **Simplicity**: This approach uses pure functions for core logic, minimizing complexity by avoiding side effects and aligning with the philosophy's "Simplicity First" principle, trading minor initial setup for easier maintenance over time.
- **Modularity + strict separation**: Hexagonal design ruthlessly separates core business logic from I/O concerns via interfaces, directly implementing "Modularity is Mandatory" and "Strict Separation of Concerns" for independent testing and evolution.
- **Testability (minimal mocking)**: Core functions are pure and isolated, enabling unit tests without mocking internal components as per "Design for Testability," with only external I/O mocked, reducing test fragility.
- **Coding standards**: Enforces "Pure functions where possible," "Immutable data structures," and "No any" through TypeScript interfaces, while comprehensive error handling and structured logging meet "Explicit over implicit" and development standards.
- **Documentation approach**: Focuses on self-documenting code with TSDoc comments for rationale, adhering to "Document Decisions, Not Mechanics," while keeping documentation minimal and integrated.

## Build Steps
1. Define interfaces in `src/fileRewriter.ts` for content construction (e.g., `ContentBuilder`) and file operations (e.g., `FileWriter`), isolating core logic from I/O.
2. Implement pure functions for metadata combination, using `StandardYamlMetadata` and immutable patterns to produce new content strings.
3. Create adapters for atomic writes and backups, leveraging Node.js file APIs to write to temporary files then rename, with configurable backup directory.
4. Integrate `YamlSerializer` and `Logger` for serialization and structured logging, ensuring all operations handle filesystem errors with typed responses.
5. Add testing utilities, writing unit tests for pure functions and integration tests for adapters, achieving >90% coverage on core logic.
6. Implement error handling with custom typed errors and propagate via function returns, wrapping all I/O in try-catch blocks.
7. Document function signatures with TSDoc, focusing on rationale and trade-offs, and structure the module for easy extension while maintaining the single responsibility principle.
