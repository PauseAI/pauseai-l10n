# pauseai-l10n

This project provides LLM-based localization (l10n) support for the pauseai-website project, maintaining a version-controlled cache of translations and the prompts that generated them.

## Architecture

The project serves as a:
1. Cache for LLM-generated translations
2. Version control for translation prompts
3. Build-time integration for static site generation

### Translation Cache Structure
```
pauseai-l10n/
├── cache/
│   ├── en-US/                    # Source content
│   │   └── [content-hash].json   # Original content
│   ├── es/                       # Spanish translations
│   │   └── [content-hash].json   # Contains translations and metadata
│   └── ...                       # Other languages
├── prompts/
│   ├── default.txt               # Base prompt template
│   └── locale-variants/          # Optional locale-specific adjustments
│       ├── es.txt
│       └── de.txt
├── src/
│   ├── hash.ts                   # Content hashing utilities
│   ├── prompt.ts                 # Prompt generation/management
│   ├── translate.ts              # Model-agnostic interface
│   ├── models.ts                 # Simple model selection/configuration
│   └── cache.ts                  # Cache management
└── tests/
```

### Translation Flow

1. During website build:
   - Hash each source content piece
   - Check cache for existing translation
   - If missing/outdated, generate new translation via LLM
   - Store result in cache
   - Generate static pages for each locale

### Cache Entry Format
```json
{
  "sourceHash": "hash-of-original-content",
  "sourceContent": "Original en-US content",
  "translations": [
    {
      "content": "Translated content",
      "timestamp": "2024-03-20T12:00:00Z",
      "model": "gpt-4",  // Simple identifier for tracking/analysis
      "prompt": {
        "template": "default",
        "version": "v1.2"
      },
      "feedback": [
        {
          "source": "discord",
          "comment": "Good translation but formal tone",
          "timestamp": "2024-03-21T14:30:00Z"
        }
      ],
      "status": "active"
    }
  ],
  "metadata": {
    "path": "about/mission.md",
    "type": "page",
    "lastModified": "2024-03-20T12:00:00Z"
  }
}
```

## Development Priorities

1. Core Infrastructure
   - Content hashing mechanism
   - Cache storage/retrieval
   - Model-agnostic LLM interface
   - Model-specific adapters

2. Prompt Engineering
   - Base prompt template
   - Model-specific variants
   - Locale-specific variants
   - Whole-page translation focus

3. Build Integration
   - Svelte/Netlify integration
   - Incremental translation
   - Preview system

4. Monitoring/Validation
   - Translation quality metrics
   - Cost tracking
   - Cache statistics

## Getting Started

1. Set up development environment:
   ```bash
   npm init
   npm install @types/node openai
   ```

2. Create basic cache structure:
   ```bash
   mkdir -p cache/{en-US,es,fr} prompts src tests
   ```

3. Link for local development:
   ```bash
   npm link
   cd ../pauseai-website
   npm link pauseai-l10n
   ```

## Next Steps

1. Implement content hashing
2. Create basic cache management
3. Develop initial prompt template
4. Set up LLM integration
5. Create build-time hooks
6. Add monitoring/logging 