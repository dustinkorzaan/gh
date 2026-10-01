---
applyTo: "ui/**"
---

# UI (`/ui`): Vite + React + Redux Toolkit

- State lives in RTK slices; server data goes through RTK Query (or thunks
  that match the existing pattern). Keep selectors memoized.
- Request/response types must match the API's DTOs exactly; update both sides
  in the same PR.
- Render loading and error states for every server call.
- File upload/download: ask the API for a SAS URI, then talk to Blob Storage
  directly. Never send file bytes to the API.
- Auth uses Entra ID (MSAL). Send the access token to the API; never make
  authorization decisions only in the UI.
- Unit tests sit next to the code (`*.test.ts(x)`); end-to-end tests live in
  `ui/e2e/` and run with Playwright.
- `npm test -- --run` must run the unit tests once (no watch mode).
