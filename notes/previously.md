# Previous Development Notes

## Current System Analysis

1. Translation Flow
   - Uses Paraglide for UI string management
   - Git-based caching of translations
   - Two-pass translation (initial + review)
   - Heavy preprocessing/postprocessing of markdown
   - Serial Git operations with queue

2. Code Structure
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

3. Proposed Changes
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

## Development Status

1. Initial Setup Complete
   - Basic project structure
   - TypeScript configuration
   - Documentation framework
   - GitHub repository under PauseAI organization

2. Next Development Priorities
   - Implement LLM request caching
   - Add translation comparison UI
   - Simplify markdown handling
   - Streamline validation approach

## Key Learnings

1. Translation Approach
   - Trust capable models more
   - Reduce preprocessing complexity
   - Handle special cases via prompts
   - Keep validation lightweight and optional
   - Surface comparisons for review

2. Technical Insights
   - Cache LLM requests not just results
   - Maintain full context for auditability
   - Simple validation over complex preservation
   - Preview-based comparison workflow
   - Focus on native speaker review process

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

1. Short Term
   - Deploy prototype branch
   - Add LLM request caching
   - Implement comparison UI
   - Test with native speakers

2. Medium Term
   - Complete transition to new cache
   - Simplify markdown handling
   - Streamline validation
   - Document new architecture

3. Long Term
   - Optimize model selection
   - Enhance prompt engineering
   - Scale to more languages
   - Consider community feedback system