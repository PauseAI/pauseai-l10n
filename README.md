# pauseai-l10n

LLM-based localization support for the pauseai-website project. This package maintains a version-controlled cache of translations and the prompts that generated them.

## Project Status

The plan is to swap this in for the https://github.com/PauseAI/paraglide repos before too long.

In the meantime time I'm already stashing notes here for the ongoing work to productionize the website [paraglide branch](https://github.com/PauseAI/pauseai-website/blob/paraglide/README.md) and then expose the first few languages in mainline.

See [notes/kickoff.md](notes/kickoff.md), [previously.md](notes/previously.md) and ongoing development [summary](notes/summary) for evolving design and architecture details.

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