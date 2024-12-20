# pauseai-l10n

This project provides localization (l10n) support for the pauseai-website project.

## Development Approach

There are two main approaches to developing this dependency:

1. **Independent Repository (Current)**: 
   - Pros:
     - Clean separation of concerns
     - Can be reused by other projects
     - Clear version control history
   - Cons:
     - More complex to test integration during early development
     - Need to publish/link for testing

2. **Monorepo First**:
   - Pros:
     - Easier initial integration testing
     - Can evolve API naturally with the main project
   - Cons:
     - Extra work to extract later
     - Risk of tight coupling

### Recommendation

For this case, starting as an independent repository (current approach) is recommended because:

1. The functionality (localization) is well-defined and naturally separable
2. The interface between website and l10n is likely to be relatively stable
3. Independent versioning will be valuable as translations grow
4. Other projects may benefit from reusing this package

## Getting Started

1. Initialize the project:
   ```bash
   npm init
   ```

2. Link for local development:
   ```bash
   npm link
   cd ../pauseai-website
   npm link pauseai-l10n
   ```