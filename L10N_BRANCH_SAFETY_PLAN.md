# L10n Branch-Based Safety and Simplification Plan

## Overview
This plan outlines the transition from a complex flag-based translation system to a simpler branch-based approach that prevents accidental pollution of production translation caches.

## Current Problems
1. **Multiple overlapping flags**: `--dry-run`, `L10N_FORCE_TRANSLATE`, dev/prod logic
2. **Risk of polluting main**: Developers could accidentally write to production translation cache
3. **Complex pnpm targets**: `translate:dry-run`, `translate:estimate`, `translate:spend`
4. **Inconsistent terminology**: Mix of "translate" and "l10n" throughout codebase

## Proposed Solution

### Core Principle: Branch-Based Isolation
- Each website branch gets its own translation cache branch
- Developers cannot write to main translation branch from local machines
- CI/CD automatically determines appropriate branch

### Branch Mapping
```
pauseai-website branch → translation-cache branch
main                  → main
feat/new-page        → feat/new-page  
pr-123               → pr-123
l10-preview          → l10-preview
```

### Implementation Details

#### 1. Environment Variable Strategy (TODO)
```typescript
// Automatic branch detection
const getTranslationBranch = () => {
  if (process.env.TRANSLATION_BRANCH) return process.env.TRANSLATION_BRANCH
  if (process.env.CI === 'true') {
    if (process.env.REVIEW_ID) return `pr-${process.env.REVIEW_ID}`
    return process.env.BRANCH || 'main'
  }
  return getCurrentGitBranch()
}

// Safety check
const validateForWrite = (branch: string) => {
  if (process.env.CI !== 'true' && branch === 'main') {
    throw new Error('Cannot write to main from local development')
  }
}
```

**Rationale**: 
- CI environment variable clearly distinguishes CI/CD from local dev
- Netlify provides REVIEW_ID for PR previews, BRANCH for branch deploys
- Local development defaults to current git branch

#### 2. Simplified Translation Modes (TODO)
Remove complex flags in favor of three clear operations:
- **l10n:estimate** - Shows what needs translating (no LLM calls)
- **l10n** - Standard operation (reads cache, generates missing)
- **Read-only mode** - Simply comment out `TRANSLATION_OPENROUTER_API_KEY` in .env

**Rationale**: 
- Cleaner mental model, every translation run is useful and recoverable
- Read-only mode achieved by absence of API key is more intuitive than managing separate boolean
- Developers can easily toggle by commenting/uncommenting the API key line

#### 3. Translation Script Updates (TODO)
- Rename all files/functions from `translate*` to `l10n*`
- Remove `L10N_FORCE_TRANSLATE` environment variable
- Remove `--dry-run` flag (use branch instead)
- Update `git-ops.ts` to use branch detection logic
- Remove hardcoded `LOCAL_TESTING_BRANCH`

#### 4. Git Operations (TODO)
- Automatic branch creation/checkout based on website branch
- Push with `--set-upstream` to create remote branches
- Handle fresh clones gracefully

### Benefits
1. **Safety**: Impossible to accidentally pollute production cache
2. **Simplicity**: Branch determines everything, no complex flags
3. **Reusability**: Test translations can be merged to production
4. **Auditability**: Clear branch history for translations

### Migration Path
1. ✅ Update terminology (translate → l10n) in non-breaking places
2. ✅ Add smart guards to postbuild scripts
3. TODO: Implement branch detection logic
4. TODO: Update translation scripts to use new approach
5. TODO: Remove deprecated flags and options
6. TODO: Update documentation

### Special Considerations

#### PR Preview Translations
- PR previews automatically generate to `pr-{number}` branches
- Translations persist across preview rebuilds
- Can be merged to main after review

#### Local Development
- Most developers never interact with translation repos (en-only)
- Explicit `TRANSLATION_BRANCH=my-test` required for LLM usage
- `netlify serve` can read from main safely with `TRANSLATION_READONLY=true`

#### Branch Promotion
```bash
# After PR approval, promote translations
cd translation-cache
git checkout main
git merge pr-123
git push
```

### Open Questions
1. Should we implement a GitHub Action to auto-merge translation branches when PRs merge?
2. How do we handle translation cache cleanup for old branches?
3. Should preview branches share translation cache to reduce costs?

### Testing Plan (TODO)
1. Test branch detection in various environments
2. Verify safety checks prevent main pollution
3. Test PR preview → production promotion flow
4. Ensure backwards compatibility during migration