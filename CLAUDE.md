# CLAUDE.md pauseai-l10n project context

This project concerns automatic localization of the PauseAI.info website (and later, possibly other text resources.)

The website is written in SvelteKit, is mostly static, served from Netflify. (A little dynamic content is fetched from AirTable.)

Our key idea is that as of 2025 a mostly text website is best localized by LLMs.
Manual edits to generated content are to be avoided outside of emergency operational actions.
Instead, we "edit" content by adding to the prompt(s) that generate that localized content.

A second idea is that the generated content is itself stored in a Git-managed cache. This is for two reasons:
- avoid unnecessary token cost: don't run the same l10n request against the same LLM twice.
- for visibility: capture our exploration of l10n choices made throughout development

This project `pauseai-l10n` is to become a dependency of the mainline pauseai-website. For now it contains mostly documentation.

Related current work is visible under notes/references, where
- `website-prototype` contains a prototype `paraglide` branch of the GitHub `pauseai-website` repository.
- `repos_paraglide` contains a first cut of the Git-managed cache. `pause-l10n` will absorb it and code to manage it.
- `website-mainline` contains the production deployed `pauseai-website` repos, which will merge back the prototype branch soon.

Here is the prototype's l10n flow, which we hope to simplify by using better LLMs:
   - Git-based caching of translations, currently through OpenRouter + Llama 
   - Two-pass translation (initial + review)
   - Separate aggregated short messages, and markdown for titled pages 
   - Heavy preprocessing/postprocessing of said markdown
   - Serial Git operations with queue

## Existing code structure, and proposed replacement:

   ```typescript
   // Current translation flow
   async function translate(...) {
     const processed = preprocessMarkdown(content)
     const firstPass = await postChatCompletion([...])
     const reviewed = await postChatCompletion([..., reviewPrompt])
     return postprocessMarkdown(processed, reviewed)
   }

   // Current caching approach
   const cacheLatestCommitDate = cacheLatestCommitDates.get(path)
   if (cacheLatestCommitDate > sourceLatestCommitDate) {
     useCachedTranslation = true
   }
   ```

   ```typescript
   // New translation request caching
   interface TranslationRequest {
     source: string
     prompt: string
     model: string
     timestamp: string
   }

   // New translation flow with comparison
   async function translate(...) {
     const request = {
       source: content,
       prompt: promptGenerator(languageName, content, promptAdditions),
       model: LLM_MODEL,
       timestamp: new Date().toISOString()
     }

     const oldResult = await checkOldCache(...)
     const newResult = await getOrCreateNewTranslation(request)
     
     if (process.env.NODE_ENV === 'development') {
       // Surface comparison in preview
     }
     
     return oldResult // Use old system during transition
   }

   // Preview comparison component
   <script lang="ts">
     import { diff_match_patch } from 'diff-match-patch'
     
     export let translations: Record<string, {old?: string, new: string}>
     
     function renderDiff(old: string, newText: string) {
       const dmp = new diff_match_patch()
       const diff = dmp.diff_main(old, newText)
       return // HTML with diff highlighting
     }
   </script>
   ```

## Key Architectural Decisions

1. Cache Structure
   - Moving from translation caching to LLM request caching
   - Store full context (source, prompt, model, result)
   - Simpler validation approach vs complex preprocessing
   - Git-based storage with clean data model
   - Focus on auditability and reproducibility

2. Translation Strategy
   - Trust capable models (GPT-4/Claude) more
   - Reduce preprocessing/postprocessing complexity
   - Opt-in validation for special cases
   - Whole-page translation approach preferred
   - Prompt engineering over code complexity

3. Project Organization
   - Independent repository (vs monorepo)
   - TypeScript-based implementation
   - Build-time integration with pauseai-website
   - Cache as version-controlled translation history

4. Transition Approach
   - Deploy prototype first for immediate progress
   - Build new cache format alongside old system
   - Surface translation comparisons in preview site
   - One-time switch once validated by native speakers
   - Maintain existing review process via Discord


## Open Questions

1. Model Selection
   - Cost vs quality tradeoffs
   - Single vs two-pass approach
   - Specific model recommendations pending testing
   - Token cost analysis needed

2. Integration Details
   - Preview system comparison UI
   - Translation metadata handling
   - Diff visualization approach
   - Monitoring and cost tracking

3. Validation Strategy
   - Balance between trust and verification
   - Opt-in validation criteria
   - Special case handling via prompts
   - Native speaker review process


## Implementation Plan

1. Short Term (on paraglide branch)
   - Add LLM request caching
   - Implement comparison UI
   - Test with native speakers
   - Once verified, remove comparison and go forward with cached requests
   - **fold paraglide into mainline at this point** modulo any "keep production stable" nuances

2. Medium Term (on pauseai-l10n)
   - Complete transition to new cache
   - Simplify markdown handling
   - Streamline validation
   - Document new architecture

3. Long Term
   - Optimize model selection
   - Enhance prompt engineering
   - Scale to more languages
   - Consider community feedback system


# Maintaining documentation

It's early days for documenting AI-assisted codebases, and developer Anthony has lots to learn re this and the particular tech stack.

Current approach:

Previous chat sessions have been summarized for fellow human developers and AI coding helpers like yourself, focusing on decisions and current status.

See notes/summary/YYYYMMDDTHH.[named session].summary.md

The original raw chats get captured too, but I won't often want you to read them. In them I will make asides, tell you how I'm doing, go off into the weeds in the meta of using Cursor, learn brand new things everyone else already knows. We don't want to waste space on that content within summaries, but I do want to keep highlights in personal summaries not meant for others to read in parallel notes/personal/YYYYMMDDTHH.*.personal.md

At the end of each session, I'll want you to help me produce those summaries for next time.

# Recent Progress

## 2025-03-02: Centralizing Localization Paths
- Created `/src/lib/l10n-paths.ts` to centralize localization path configuration
- Added validation in vite.config.ts to prevent confusing errors when starting dev server
- Identified opportunities to optimize build process performance:
  - Reduce verbosity for unchanged translations
  - Parallelize markdown processing 
  - Address build warnings
- These changes lay groundwork for implementation of the comparison UI and LLM request caching



# General pauseai-l10n Development Guidelines - brewed by Claude on first run

## Build & Test Commands
- Build: `npm run build`
- Test: `npm run test
- Run single test: `npx jest path/to/test.ts`
- Clean: `npm run clean`

**Formatting:**
- No semicolons; use tabs for indentation
- Single quotes; 100 character line width
 - No trailing commas

**TypeScript:**
- Strict type checking enabled
- ES2020 target with CommonJS modules

**Imports:**
- Use ES module syntax with esModuleInterop

**File Organization:**
- Source code in `src/`
- Tests in `tests/` (excluded from build)
