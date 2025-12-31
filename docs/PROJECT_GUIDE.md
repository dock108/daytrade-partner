# TradeLens Project Guide

## Project Structure

The project follows a clean architecture pattern with clear separation of concerns:

```
TradeLens/
├── TradeLens.xcodeproj/        # Xcode project configuration
└── TradeLens/                  # Main application directory
    ├── TradeLensApp.swift      # Application entry point
    ├── Info.plist              # App configuration
    ├── Models/                 # Data models and business entities
    │   └── Trade.swift         # Example: Trade entity
    ├── Services/               # Business logic and data management
    │   └── TradeService.swift  # Example: Trade data service
    ├── Views/                  # SwiftUI view components
    │   └── ContentView.swift   # Main content view
    ├── ViewModels/             # View state and presentation logic
    │   └── TradeListViewModel.swift # Example: Trade list view model
    ├── Utilities/              # Helper functions and extensions
    │   └── CurrencyFormatter.swift # Example: Currency formatting utilities
    ├── Assets.xcassets/        # Image and color assets
    └── Preview Content/        # Resources for SwiftUI previews
```

## Architecture Overview

### Models
Contains data structures and business entities. Models should be:
- **Codable** for JSON serialization
- **Identifiable** when used in SwiftUI lists
- **Immutable** when possible (use `let` instead of `var`)
- Well-documented with clear property purposes

### Services
Houses business logic, API clients, and data management. Services should:
- Use `@MainActor` for UI-related state
- Leverage Swift Concurrency (`async/await`)
- Be protocol-based for testability
- Handle all data persistence and networking

### Views
SwiftUI view components representing the UI. Views should be:
- Small and focused on a single responsibility
- Stateless when possible
- Leverage `@State`, `@Binding`, and `@ObservedObject` appropriately
- Include `#Preview` for rapid development

### ViewModels
Presentation logic and view state management. ViewModels should:
- Use `@MainActor` for main thread operations
- Conform to `ObservableObject`
- Expose `@Published` properties for reactive UI updates
- Keep views thin by handling business logic

### Utilities
Reusable helper functions, extensions, and formatters. Utilities should be:
- Stateless and pure when possible
- Well-tested
- Generic and reusable across the app

## Key Features

### Swift Concurrency
The project is configured with strict concurrency checking:
- **Async/await** for asynchronous operations
- **Actors** for thread-safe state management
- **@MainActor** for UI updates
- Eliminates data races at compile time

Build settings include:
```
SWIFT_STRICT_CONCURRENCY = complete
```

### Modern SwiftUI
- Uses latest SwiftUI components and patterns
- NavigationStack for modern navigation
- Preview providers for rapid iteration
- iOS 17.0+ deployment target

## Development Guidelines

### Code Style
- Use clear, descriptive names for types and properties
- Keep files small and focused (under 300 lines when possible)
- Add documentation comments for public APIs
- Follow Swift naming conventions

### Best Practices
1. **Separation of Concerns**: Keep business logic out of views
2. **Dependency Injection**: Pass dependencies through initializers
3. **Error Handling**: Use proper error handling with Result types or throws
4. **Testing**: Write unit tests for ViewModels and Services
5. **Previews**: Always include SwiftUI previews for views

### Git Workflow
- Keep commits atomic and well-described
- Use feature branches for new functionality
- Review code before merging

## Requirements

- **iOS**: 17.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

## Building the Project

The project uses standard Xcode build settings:
- **Debug**: Full optimization off, debugging symbols included
- **Release**: Whole module optimization, no debug symbols

## Future Enhancements

This is a foundational structure ready for expansion:
- Real-time market data integration
- Trade history and analytics
- Portfolio tracking
- Risk management tools
- Social trading features

## License

This project is part of the daytrade-partner repository.

## Contributing

When adding new features:
1. Place files in the appropriate folder based on their responsibility
2. Keep the structure clean and maintainable
3. Update documentation if adding new major components or patterns
4. Add comments explaining non-obvious code
