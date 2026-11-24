# Crate Expectations

WoW: Forever addon by cnhermey: Auction House costs for each bundle on Waylaid
crate tooltips, from Auctionator's prices (required dependency). Player's install:
`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\CrateExpectations\`.
Follow the `wow-forever-addon-dev` skill's conventions.

Named "Waylaid" until v0.3.0 (that name was taken on CurseForge). Folder, TOC and
globals are `CrateExpectations`; slash `/crate`. Repo: cnhermey/CrateExpectations.

## Releasing (automatic)

Every update ships as a release, and GitHub builds it, not Claude.

1. Bump `## Version: X.Y.Z` in `CrateExpectations.toc` and the README title
   `# Crate Expectations (vX.Y.Z)` (patch for fixes, minor for features).
2. Add `## X.Y.Z (YYYY-MM-DD)` at the top of `CHANGELOG.md` with bullets
   written for players. This section becomes the release notes.
3. Commit and push to `main`. `.github/workflows/release.yml` zips the addon
   as `CrateExpectations/` and creates release `vX.Y.Z` with `CrateExpectations-vX.Y.Z.zip`.
4. Copy the changed files into the player's AddOns folder too.

CurseForge upload runs once `CF_API_KEY` is a repository secret and
`CrateExpectations.toc` has `## X-Curse-Project-ID: <id>`; until then that step skips.
Files that shouldn't be in the zip go in `.gitattributes` as `export-ignore`.
