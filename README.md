# pauseai-l10n

LLM-based localization support for the pauseai-website project. This package maintains a version-controlled cache of translations and the prompts that generated them.

## Project Status

Currently in early development. See [notes/pauseai-l10n-kickoff.md](notes/pauseai-l10n-kickoff.md) for design and architecture details.

## Development Setup

```bash
# Install dependencies
npm install

# Link for local development
npm link
cd ../pauseai-website
npm link pauseai-l10n
```

## Project Structure

```
pauseai-l10n/
├── cache/          # Translation cache storage
├── prompts/        # Translation prompt templates
├── src/           # Source code
├── tests/         # Test files
└── notes/         # Design documents and notes
```

## License

TBD 