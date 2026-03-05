# Paraglide Edge Function Window.location Bug Investigation

## Date: 2025-11-13

## Root Cause Identified

**Problem:** Dynamic pages (prerender=false) return HTTP 500 on first request to cold Netlify edge functions.

**Root Cause:** Netlify's Deno 2.3.1 edge runtime provides a partial `window` object that breaks paraglide-js assumptions.

### Environment Comparison

| Environment | Deno Version | window exists | window.location exists | Behavior |
|-------------|--------------|---------------|------------------------|----------|
| Local (netlify serve) | 2.2.4 | ❌ false | ❌ N/A | ✅ Works - no window |
| Production Edge | 2.3.1 | ✅ true | ❌ undefined | ❌ Crashes on window.location.href |
| Browser | N/A | ✅ true | ✅ defined | ✅ Works - full window |
| Node.js SSR | N/A | ❌ false | ❌ N/A | ✅ Works - no window |

**Discovery Method:** Created `/api/deno-version` diagnostic endpoint (PR #544) which revealed:
- `navigator.userAgent: "Deno/2.3.1"` (production)
- `window` exists but `window.location` is `undefined`
- Netlify provides window stub for library compatibility but incomplete implementation

### Why Deno 2.x Removed Window

From GitHub issue denoland/deno#25797 (Sept 2024):
- Deno 2.0 removed `window` global to improve ecosystem compatibility
- Libraries use `typeof window !== "undefined"` to detect browsers
- Having window in server runtime caused more problems than it solved
- Recommendation: Use `globalThis` instead

**Netlify's divergence:** Re-added partial window for compatibility, creating new incompatibility.

## Paraglide Bugs - Complete List

All bugs stem from missing `!isServer` guard on browser-only API access.

### Bug Location 1: setLocale() - Line 289-302 (CONFIRMED CRASH)

**File:** `src/lib/paraglide/runtime.js:289-302`
**Upstream:** `inlang/packages/paraglide/paraglide-js/src/compiler/runtime/set-locale.js:~100-113`

```javascript
else if (TREE_SHAKE_URL_STRATEGY_USED &&
    strat === "url" &&
    typeof window !== "undefined") {  // ← MISSING !isServer
    newLocation = localizeUrl(window.location.href, {  // 💥 CRASH
        locale: newLocale,
    }).href;
}
```

**Evidence:** Stack trace from issue #540:
```
TypeError: Cannot read properties of undefined (reading 'href')
  at C4 (../../src/lib/paraglide/runtime.js:300:54)
  at setLocale (../../src/lib/paraglide/runtime.js:183:16)
  at getLocale (../../src/lib/paraglide/runtime.js:1155:26)
```

**Status:** ❌ Not fixed by our isServer changes

### Bug Location 2: getLocale() - Line 143-147 (FIXED)

**File:** `src/lib/paraglide/runtime.js:143-147`
**Upstream:** `inlang/packages/paraglide/paraglide-js/src/compiler/runtime/get-locale.js:63-68`

```javascript
else if (TREE_SHAKE_URL_STRATEGY_USED &&
    strat === "url" &&
    !isServer &&  // ✅ HAS guard
    typeof window !== "undefined") {
    locale = extractLocaleFromUrl(window.location.href);
}
```

**Status:** ✅ Has isServer guard (but still redundant with our isServer definition)

### Bug Location 3: setLocale() localStorage - Line 304-308 (POTENTIAL)

**File:** `src/lib/paraglide/runtime.js:304-308`

```javascript
else if (TREE_SHAKE_LOCAL_STORAGE_STRATEGY_USED &&
    strat === "localStorage" &&
    typeof window !== "undefined") {  // ← MISSING !isServer
    localStorage.setItem(localStorageKey, newLocale);  // Would crash if called
}
```

**Status:** ❌ Missing guard, not yet encountered in practice

### Bug Location 4: getUrlOrigin() - Line 371-375 (POTENTIAL)

**File:** `src/lib/paraglide/runtime.js:371-375`

```javascript
else if (typeof window !== "undefined") {  // ← MISSING guard
    return window.location.origin;  // Would crash if called
}
```

**Status:** ❌ Missing guard, may be called by shouldRedirect()

### Correct Implementation Example: Line 1099

```javascript
if (typeof window !== "undefined" && window?.location?.href) {
```

Uses optional chaining - this pattern works correctly.

## Our Fix Attempt #1: Runtime isServer Check

**Changed:** `scripts/inlang-settings.ts:129-131`

```javascript
// OLD (from PR #379):
isServer: 'import.meta.env.SSR'

// NEW:
isServer: 'typeof window === "undefined" || typeof window.location === "undefined"'
```

### Why This Approach

**Problem with import.meta.env.SSR:**
- Vite replaces it with constant `false` in edge bundles
- Bundler optimizes away `!false` as dead code
- Guard completely removed from bundled edge function

**Runtime check advantages:**
- Evaluated at runtime, not compile-time
- Bundler cannot optimize it away
- Directly tests the capability we need
- Works correctly in all three environments

### Why It Didn't Fully Work

✅ **Fixed getLocale()** - Already had `!isServer` check, now evaluates correctly
❌ **Didn't fix setLocale()** - Missing `!isServer` check entirely in source

The compiler only generates the `isServer` constant. Each usage site must check it, and setLocale() doesn't.

**Also removed:** `importRuntimeWithoutVite()` workaround - no longer needed with runtime check that works in Node.js scripts.

## Fix Options Going Forward

### Option 1: Post-Compilation Runtime Patching

**Infrastructure exists:** `investigate/500s` branch has `patch()` function in `scripts/inlang-settings.ts`

**Approach:**
```javascript
compile(compileOptions)

// Patch after compilation
patch(
    './src/lib/paraglide/runtime.js',
    'strat === "url" &&\n            typeof window !== "undefined")',
    'strat === "url" &&\n            !isServer &&\n            typeof window !== "undefined")'
)
```

**Pros:**
- Quick fix
- No upstream dependency
- Can fix multiple locations with multiple patches

**Cons:**
- Fragile if paraglide output format changes
- Need to maintain patches across paraglide updates
- Doesn't fix the underlying library

### Option 2: Pre-Compilation Source Patching

**Location:** We call `compile()` from `@inlang/paraglide-js` package

**Approach:**
- Use pnpm patch to modify the installed package
- Edit `node_modules/@inlang/paraglide-js/dist/compiler/runtime/set-locale.js`
- Add `!isServer &&` checks before window.location access
- Generate patch file for version control

**Pros:**
- Patches happen during `pnpm install`
- More maintainable than post-compilation patching
- Can include in source control via pnpm patch

**Cons:**
- Need to regenerate patch when updating paraglide version
- Still not fixing upstream

### Option 3: Fork Paraglide

**Repository:** https://github.com/opral/monorepo
**Package:** `inlang/packages/paraglide/paraglide-js`
**Our Dependency:** `@inlang/paraglide-js: ^2.4.0`

**Files to Fix:**
1. `src/compiler/runtime/set-locale.js` - Add `!isServer &&` to line ~100-103 (url strategy)
2. `src/compiler/runtime/set-locale.js` - Add `!isServer &&` to line ~115-118 (localStorage strategy)
3. `src/compiler/runtime/get-url-origin.js` or similar - Add guard to window.location.origin access

**Approach:**
1. Fork opral/monorepo
2. Create branch with fixes
3. Submit PR upstream (may take time for review/merge)
4. Point our package.json to our fork: `"@inlang/paraglide-js": "github:PauseAI/monorepo#path:inlang/packages/paraglide/paraglide-js"`
5. Switch back to npm version when upstream merges fix

**Pros:**
- Clean fix at the source
- Contributes to ecosystem
- No ongoing patch maintenance

**Cons:**
- Most complex setup
- Need to maintain fork until upstream merges
- Potential merge conflicts with upstream updates

### Option 4: Report Upstream and Wait

**Create issues at:** https://github.com/opral/inlang-paraglide-js
**Related existing issue:** #540 in PauseAI repo describes this exact problem

**Not recommended:** Blocks our ability to use dynamic pages until fixed upstream.

## Recommended Approach

**Short term (immediate):** Option 1 - Post-compilation patching
- Unblocks dynamic pages quickly
- Low risk
- Use infrastructure from investigate/500s branch

**Long term (next sprint):** Option 3 - Fork and PR upstream
- Proper fix
- Benefits entire paraglide community
- Clean maintenance path

## Testing Required

After implementing any fix, test in these contexts:

1. **Local `pnpm dev`** - Node.js development server
2. **Local `pnpm build && pnpm preview`** - Node.js SSR
3. **Local `netlify serve`** - Deno 2.2.4 edge simulation
4. **Preview deployment** - Netlify Deno 2.3.1 production edge
5. **Browser client-side** - Full window object

For preview deployment testing:
- First request must be captured (cold edge function)
- Subsequent requests verify warm state
- Test with different User-Agent to bypass cache

## Related Issues & PRs

- **#538** - Re-adding-people-page (where 500 was discovered)
- **#540** - localizeHref can't run on edge functions runtime (describes exact bug)
- **#370** - Sporadic 500 errors on /statement route (similar pattern)
- **PR #379** - Previous fix attempt using import.meta.env.SSR (failed due to bundler optimization)
- **PR #544** - Deno version diagnostic endpoint (this investigation)

## Key Commits

**In PauseAI/pauseai-website:**
- `27d6c6d` - PR #379: Changed isServer to import.meta.env.SSR (didn't work)
- `7aa82fa` - Added runtime.js patching infrastructure (investigate/500s branch)
- `391c6ba` - Our runtime isServer check fix (partial - only fixed getLocale)
- `3a80bea` - Fixed ESM imports for dynamic runtime loading

**In opral/monorepo (paraglide source):**
- `38038713e` (Apr 4, 2025) - "fix: add guard clause for window object" (only for cookies, not window.location)
- `dc287f15c` (Jun 2, 2025) - "Implement custom strategy concept for locale resolution"

## Configuration Details

**Current settings:** `scripts/inlang-settings.ts:123-132`
```javascript
const compileOptions = {
    project: './project.inlang',
    outdir: './src/lib/paraglide',
    strategy: ['url', 'cookie', 'preferredLanguage', 'baseLocale'],
    disableAsyncLocalStorage: true,  // Required for Netlify Edge
    isServer: 'typeof window === "undefined" || typeof window.location === "undefined"'
}
```

**Strategy order matters:** Falls through until match found. BaseLocale always succeeds (returns 'en').

## Why First Request Fails, Subsequent Succeed

1. **First request** - Cold edge function initialization
   - Paraglide module loads
   - `getLocale()` called during SSR
   - Calls `setLocale()` for first-time initialization (line 183)
   - `setLocale()` crashes on `window.location.href` (line 300)
   - Returns HTTP 500

2. **Subsequent requests** - Warm edge function
   - Module already initialized
   - Locale already set from first call
   - `getLocale()` short-circuits early (line 131-134: uses cached locale)
   - Never calls `setLocale()` again
   - Returns HTTP 200

3. **Cache layer** - 1 hour TTL based on User-Agent
   - Hides problem from most users
   - First visitor takes the 500 hit
   - Everyone else gets cached 200 response

## Window Modification Tests - SUCCESSFUL

**Test endpoint:** `/api/deno-version` on PR #544 branch
**Production URL:** https://deploy-preview-544--pauseai.netlify.app/api/deno-version

**Production test results (Netlify Deno 2.3.1):**
```json
{
  "can_delete_window": true,           // ✅ Can delete globalThis.window
  "can_set_window_undefined": true,    // ✅ Can set window = undefined
  "can_add_window_location": true,     // ✅ Can add window.location object
  "no_location_to_modify": true        // (window.location didn't exist to modify)
}
```

**Key Discovery:** Window global IS modifiable in Netlify edge functions!

This enables a runtime workaround without patching compiled code.

## Recommended Fix: Runtime Window Workaround (PREFERRED)

**Implementation location:** `src/hooks.server.ts` - SvelteKit server hooks run before rendering

**Approach 1 - Delete window:**
```typescript
export const handle = async ({ event, resolve }) => {
    // Remove window stub before paraglide code executes
    if (typeof window !== 'undefined' && typeof window.location === 'undefined') {
        delete (globalThis as any).window
    }
    return resolve(event)
}
```

**Approach 2 - Add window.location with request URL:**
```typescript
export const handle = async ({ event, resolve }) => {
    if (typeof window !== 'undefined' && typeof window.location === 'undefined') {
        // Provide window.location using actual request URL
        (window as any).location = {
            href: event.url.href,
            pathname: event.url.pathname,
            origin: event.url.origin,
            search: event.url.search,
            hash: event.url.hash
        }
    }
    return resolve(event)
}
```

**Pros:**
- Simplest implementation (few lines of code)
- No compilation/patching infrastructure needed
- Uses actual request URL (semantically correct)
- Easy to understand and maintain
- Can be removed when paraglide or Netlify fix upstream

**Cons:**
- Workaround rather than proper fix
- Need to verify hooks run before paraglide module initialization
- May need testing to ensure doesn't break other window-dependent code

**Status:** Preferred approach - try this first before patching.

## Next Steps

1. ✅ **Window modification tests completed** - We CAN modify window at runtime
2. **Implement runtime workaround** in `src/hooks.server.ts`
3. **Test on preview deployment** with cold edge function
4. **If successful:** Apply to main and close #538, #540
5. **Long term:** Still consider PR to paraglide upstream to fix properly

## File Locations for Reference

**Our code:**
- `scripts/inlang-settings.ts` - Calls paraglide compiler, sets isServer option
- `src/lib/paraglide/runtime.js` - Generated by compiler (DO NOT EDIT - gets overwritten)
- `src/lib/paraglide/messages/*.js` - Generated message functions

**Paraglide source (in ~/repos/pauseai-l10n/notes/references/monorepo):**
- `inlang/packages/paraglide/paraglide-js/src/compiler/runtime/get-locale.js`
- `inlang/packages/paraglide/paraglide-js/src/compiler/runtime/set-locale.js`
- Both contain window.location.href access without proper guards

**Dependency:** `@inlang/paraglide-js: ^2.4.0` (package.json)

## Alternative: Bypass Netlify Edge Functions

If patching proves too fragile, could:
- Set `export const config = { runtime: 'nodejs' }` in routes (if supported)
- Use serverless functions instead of edge (slower but no window stub)
- Make pages static (prerender = true) - but loses dynamic functionality
- Switch hosting providers (Vercel, Cloudflare have different edge runtimes)

Not recommended - fixing paraglide is better for ecosystem.
