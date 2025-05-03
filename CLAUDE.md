# CLAUDE.md pauseai-l10n project context

This project concerns automatic localization of the PauseAI.info website (and later, possibly other text resources.)

The website is written in SvelteKit, is mostly static, served from Netlify. (A little dynamic content is fetched from AirTable.)

## Current Status (April 28, 2025)
- ✅ Full internationalization is now integrated into the main branch of pauseai-website
- ✅ The paraglide prototype has been squashed and merged 
- ✅ Website builds with English-only by default for development convenience
- 🔄 Non-English locales will be enabled once remaining issues are resolved

Our key idea is that as of 2025 a mostly text website is best localized by LLMs.
Manual edits to generated content are to be avoided outside of emergency operational actions.
Instead, we "edit" content by adding to the prompt(s) that generate that localized content.

A second idea is that the generated content is itself stored in a Git-managed cache. This is for two reasons:
- avoid unnecessary token cost: don't run the same l10n request against the same LLM twice.
- for visibility: capture our exploration of l10n choices made throughout development

The top-level project `pauseai-l10n` is to become a dependency of the mainline pauseai-website.
For now it contains mostly documentation. Don't look for code there!

Previously we were making changes to code that lived in notes/references/website-prototype,
but that work has now been merged to main. The website-prototype directory is kept for historical 
reference but is no longer actively developed.

More generally the related current work is visible under notes/references, where
- `website-mainline` contains the production deployed `pauseai-website` repository, which now includes all paraglide localization code.
- `repos_paraglide` contains a first cut of the Git-managed cache. `pause-l10n` will absorb it and code to manage it.
- The inactive `website-prototype` contains the historical prototype `paraglide` branch that was merged to main.
- The `monorepos` contains source code when you want to dig into the inlang and paraglide frameworks, since reading the node distribution chunks is a bit of a pain.

The current implementation's l10n flow (now in the main branch):
   - Git-based caching of translations, through OpenRouter + Llama 3.1
   - Two-pass translation (initial + review)
   - Separate aggregated short messages (en.json) and markdown for titled pages 
   - Preprocessing/postprocessing of markdown for proper handling
   - Serial Git operations with queue
   
Key components in the main branch implementation:
   - Environment-based configuration with PARAGLIDE_LOCALES env var
   - Language switching UI with auto-detection in the header
   - Default English-only mode for developer convenience
   - Prerendering of all locale paths for static site generation


# General pauseai-l10n Development Guidelines - brewed by Claude on first run

**Formatting:**
- No semicolons; use tabs for indentation; Single quotes; 100 character line width; No trailing commas
- if you see deviations, stop and let me know

**TypeScript:**
- Strict type checking enabled
- ES2020 target with CommonJS modules

**Imports:**
- Use ES module syntax with esModuleInterop


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


# Some detail of how building and locale overrides work

Locally in development PARAGLIDE_LOCALES effectively defaults to just "en". A specific choice can be made in the .env file. (In production, the default is to all locales, but again environment variables may be defined to override that. We might do this when first exposing our localizable website in production - we'd like individuals to assess previews before putting the first translations live.)

Due to wanting to implement overrides, our default settings are defined as a JSON object in project.inlang/default-settings.js.  Certain vite targets use inlang-settings.ts to create what the paraglide sveltekit plugin actually expects as source for building and running - a static project.inlang/settings.json file - and get paraglide to compile this into the code that manages locales at runtime (it builds src/lib/paraglide/runtime.js)  We copy default-settings.js to a browser accessible file too, so that a running developer server can compare the current runtime against defaults and overrides and tell the developer when the server needs restarted.)

I suggest reading pnpm targets at the top of packages.json, and the default-settings.js - but leave other files uninspected until necessary.


# Implementation Plan

0. ✅ ~~COMPLETED~~ Fixes to make it reasonable to push and deploy to the prototype/paraglide branch:
   - ✅ Mend anything broken about build targets in production - by running them on developer machine
   - ✅ Support translation development on some developer machine

1. ✅ Merged paraglide to main with safety controls (April 28, 2025)
   - ✅ Ready to merge paraglide back onto main, ending cost of maintaining the branch
     - ✅ Will use PARAGLIDE_LOCALES=en in CI/CD deployment to keep locales unlaunched
   - ✅ Successfully squashed 95 commits from paraglide branch into a single comprehensive commit on main
     - ✅ Detailed commit message documenting five key development phases
     - ✅ Original paraglide branch preserved for historical reference
   - 🔄 Fix remaining issues before enabling non-English locales:
     - Isolate cache repositories by branch (prevent dev/preview from writing to production cache)
     - Resolve geo location detection failures
     - Localize non-static resources that still only show English content:
       - Search results
       - All pages list
       - RSS feed
       - Teams/People pages
       - Email builder
       - Write functionality
   - Create user-facing documentation explaining the l10n status:
     - How users can help more locales become enabled
     - How to report translation problems
     - Explanation of our LLM usage for translations (ethical considerations)
   - Validate some locales asap to realize value in production website
     - Test with native speakers
     - We may need better models for sufficiently good translations, if so suggest switch cache first
     - Otherwise launch some locales in production!
   - Supporting other models:
     - Switch to LLM request caching
     - Implement a comparison UI for dev/preview validation
     - Once verified, remove comparison(?) and go forward with cached requests

2. Medium Term (take dependency on pauseai-l10n and move relevant code there)
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

As per previous general notes. Please use notes/summary and notes/personal in the top-level pauseai-l10n project to store summaries.


# How you can be most helpful as a coding assistant

As pre previous general notes. We are a CODING CENTAUR who acts once we've agreed on the plan.
