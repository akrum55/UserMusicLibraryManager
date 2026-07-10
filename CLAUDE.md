# UserMusicLibraryManager

macOS app (Swift / SwiftUI) for managing a master FLAC library: reading and
editing metadata, persisting user edits separately from file tags, and syncing
per-user subsets to devices (iPods, Sony MP3 players).

Built by Austin, who is learning Swift as the project goes. When you use a
non-obvious Swift or SwiftUI concept, explain it in a sentence or two.

---

## Tech stack

- **Language:** Swift, with a small Objective-C++ bridge for TagLib
- **UI:** SwiftUI (`NavigationSplitView` — album list left, song list right)
- **Target:** macOS (sandboxed; see `UserMusicLibraryManager.entitlements`)
- **Metadata (three layers):**
  1. AVFoundation + `AVMetadataItem` — PRIMARY reader (`AudioMetadataReader.swift`)
  2. `FlacMetadataReader.swift` — pure-Swift FLAC fallback
  3. TagLib via `FlacTagsWrapper.mm` + `UserMusicLibrary-Bridging-Header.h`
     (static libs in `TagLib/lib/libtag.a`, `libtag_c.a`)
- **IDE:** Xcode
- **Library location:** per-user folders on an external SSD (`/Volumes/Extreme SSD`)

---

## Build & run

Command-line builds MUST disable code signing, or they fail:

```bash
xcodebuild -project UserMusicLibraryManager.xcodeproj \
  -scheme UserMusicLibraryManager \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

The repo also has a `build.sh` that runs the signed-off build and commits on
success. There's an existing convention of tagging good builds as
`working-YYYYMMDD-HHMMSS` — keep using it if you like checkpoint tags.

---

## Architecture (real layout — everything lives under `Sources/`)

- `Sources/UserMusicLibraryManagerApp.swift` — app entry point.
- `Sources/Models/Song.swift` — core model. **`Song` is a `class`** (Identifiable,
  Equatable/Hashable by `url`). Holds a nested `UserOverrides` struct whose fields
  live under `.edits.<field>` (title, artist, album, trackNumber, genre, year,
  totalTracksInAlbum, isTotalTracksInAlbumGuessed, playCount, lastPlayedDate,
  rating). Exposes a family of `effective*` computed properties, e.g.
  `effectiveTrackNumber` returns `userOverrides?.edits.trackNumber ?? trackNumber`.
  `applyOverride(_:)` merges an incoming override in. NOTE: some `effective*`
  getters (genre, year, rating) read ONLY from the override with no file fallback —
  be deliberate if you change that.
- `Sources/Models/UserOverridesStore.swift` — persistence. Static `save`/`load`
  write `overrides.json` to Application Support
  (`~/Library/Application Support/UserMusicLibraryManager/overrides.json`), keyed
  by standardized file-URL string. This is the real override store.
- `Sources/Views/ContentView.swift` — main UI (`NavigationSplitView`).
- `Sources/Views/SongDetailView.swift` — song detail. Uses `@Binding var song` so
  edits reflect live. If detail edits stop showing up, check the binding chain first.
- `Sources/Views/SongMetadataEditor.swift` — edit form.
- `Sources/Views/AlbumEditorView.swift`, `FolderPickerView.swift` — supporting views.
- `Sources/Metadata/AudioMetadataReader.swift` — AVFoundation reader (primary).
- `Sources/Metadata/FlacMetadataReader.swift` — Swift FLAC fallback reader.
- `Sources/Utilities/FolderAccessManager.swift` — sandboxed folder bookmarks.
- `Sources/Utilities/MusicLibraryScanner.swift` — scans folders for audio files.
- `Sources/Cache/ArtworkCacheManager.swift` — artwork caching.
- `Sources/Extensions/…` — `NSImage+Resizing.swift`, `AVMetadataItem+Helpers.swift`.
- Obj-C++ bridge: `FlacTagsWrapper.h` / `.mm`, `UserMusicLibrary-Bridging-Header.h`.

Empty stubs (0 bytes — not yet implemented; don't assume they do anything):
`Sources/Utilities/UserMetadataStore.swift`, `Sources/Cache/ArtworkValidator.swift`.

---

## Roadmap & current stage

1. ✅ Foundation & metadata handling (FLAC parsing, artwork, basic UI)
2. 🔄 **Metadata overrides — CURRENT.** Edits persisted via `UserOverridesStore`
   and reflected live in the UI through `Song.effective*`.
3. ⬜ Export / sync (per-user folder export, iPod sync workflow)
4. ⬜ Automation & git integration (build script, auto-commit/tag on success)

Device sync design (Stage 3 reference):

```
MasterLibrary/
├── Shared/
├── UserA/
│   ├── LosslessSubset/   -> sync to iPod via Apple Music app
│   └── LossySubset/      -> direct copy to Sony MP3 player
└── UserB/ ...
```

- iPods without Rockbox must sync through Apple Music (proprietary DB).
  AppleScript / iMazing are the automation options under consideration.
- Sony MP3 players accept direct file copies.

---

## Conventions

- Before diagnosing a build or runtime error, ask to see the relevant `.swift`
  file(s) and the build log rather than guessing.
- Prefer targeted, minimal edits over rewriting whole files, unless asked.
- Tie suggestions back to the roadmap stage above.
- `Song` is a reference type — mutating a `Song` mutates it everywhere it's shared.
  Keep that in mind around the override flow.

## Don't

- Don't delete or "fix" the TagLib integration assuming it's dead code — it's wired
  in via the bridging header and `FlacTagsWrapper.mm` and coexists with the
  AVFoundation and Swift FLAC readers on purpose.
- Don't drop `CODE_SIGN_IDENTITY=""` (and the related flags) from command-line
  builds — they'll fail with signing errors.
- Don't remove the `@Binding` on `SongDetailView.song`.
- Don't commit `build/`, `DerivedData/`, `.DS_Store`, `xcuserdata/`, or `build.log`.

## Git

- Remote already configured: `github.com/akrum55/UserMusicLibraryManager` (`main`
  tracks `origin/main`). Uses existing GitHub credentials — no token setup needed.
- Never commit directly to `main`. Work on a branch.
- Commit when the build is green; optionally tag good builds `working-YYYYMMDD-HHMMSS`.
