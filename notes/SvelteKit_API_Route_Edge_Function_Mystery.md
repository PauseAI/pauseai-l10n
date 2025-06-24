# SvelteKit API Route Edge Function Mystery - SOLVED

**Date**: June 23, 2025  
**Context**: Investigating how to move `/api/write` from edge functions to serverless functions to fix timeout issues

## The Mystery

We discovered that certain API routes were **automatically excluded** from edge functions and running as serverless functions, but couldn't find where this was configured:

**Excluded from edge (running serverless):**
- `/api/posts` ✅
- `/api/signatories` ✅  
- `/api/teams` ✅

**Running in edge functions:**
- `/api/write`
- `/api/chat` 
- `/api/calendar`
- `/api/geo`
- All others...

This was visible in `.netlify/edge-functions/manifest.json` but we couldn't find any configuration file that specified these exclusions.

## Investigation Process

We searched everywhere for the configuration:
1. ❌ `netlify.toml` - No routing config
2. ❌ `svelte.config.js` - No exclude patterns in adapter
3. ❌ `scripts/exclude-from-edge-function.ts` - Only shows `/pagefind/*`
4. ❌ `scripts/opt-in-to-caching.ts` - Only sets cache policy
5. ❌ `_redirects` file - Only domain redirect
6. ❌ Manual `netlify/functions/` directory - We use SvelteKit adapter

## The Breakthrough

Found clues in the source code:

**Key evidence in `src/routes/statement/+page.ts`:**
```typescript
export const prerender = true // workaround for 500 responses

export const load = async ({ fetch, setHeaders }) => {
	const response = await fetch('api/signatories')  // ← SERVER-SIDE CALL
	// ...
}
```

**Client-side calls (stay in edge functions):**
```typescript
// In communities/+page.svelte
async function fetchUserLocation() {
	const response = await fetch('/api/geo')  // ← CLIENT-SIDE CALL
}

// In chat/+page.svelte  
const response = await fetch('api/chat', {  // ← CLIENT-SIDE CALL
	method: 'POST',
	// ...
})
```

## The Solution

**SvelteKit automatically excludes API endpoints from edge functions when they're called during server-side prerendering/build time.**

### The Pattern

**Excluded routes (serverless):**
- `/api/teams` - called from `teams/+page.ts` load function (server-side)
- `/api/posts` - called from `posts/+page.ts`, `sitemap.xml/+server.ts`, `rss.xml/+server.ts` (server-side during build)  
- `/api/signatories` - called from `statement/+page.ts` load function (server-side)

**Edge function routes:**
- `/api/geo` - called from `communities/+page.svelte` client-side (`fetchUserLocation()`)
- `/api/chat` - called from `chat/+page.svelte` client-side (form submission)
- `/api/write` - called from client-side interactions only

### Why This Makes Sense

- **Server-side calls during build** need reliable, long-running serverless functions to handle operations like Airtable fetching during prerendering
- **Client-side calls** can use faster edge functions for better performance

## Implementation

Since `/api/write` is only called client-side but we need it as serverless due to timeout issues with complex Anthropic API calls, we used manual exclusion:

**File:** `scripts/exclude-from-edge-function.ts`
```typescript
const EXCLUDE_PATHS = ['/pagefind/*', '/api/write']
```

This forces `/api/write` to run as a serverless function, avoiding edge function timeout limitations.

## Key Learnings

1. **SvelteKit is smarter than we thought** - It automatically detects which API routes need serverless vs edge functions based on usage patterns
2. **Server-side vs client-side calls have different infrastructure needs** - Server-side prerendering needs reliability, client-side needs speed
3. **Manual overrides are available** when the automatic detection doesn't match our performance requirements
4. **The `.netlify/edge-functions/manifest.json` file is generated** - It reflects SvelteKit's automatic decisions plus any manual overrides

## Related Files

- `scripts/exclude-from-edge-function.ts` - Manual exclusion configuration
- `scripts/utils.ts` - Edge function manifest manipulation utilities  
- `.netlify/edge-functions/manifest.json` - Generated manifest (not source controlled)
- Various `+page.ts` files - Server-side load functions that trigger automatic exclusions