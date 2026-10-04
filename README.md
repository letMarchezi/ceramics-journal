# 🏺 Ceramics Journal

A cute, personal iOS studio notebook for planning, visualizing, documenting
and learning from ceramic pieces.

**Plan → visualize → construct → fire → photograph → remember.**

- **Platform:** iOS 17+
- **Framework:** SwiftUI + SwiftData (local-first, fully offline)
- **Palette:** mustard · olive green · burgundy on soft cream, rounded type
- **No third-party dependencies.**

---

## Build on your Mac

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(a simple, reproducible way to create the `.xcodeproj` from `project.yml`).

### 1. Prerequisites

- A Mac with **Xcode 15 or newer** (from the Mac App Store)
- [Homebrew](https://brew.sh)

### 2. Generate the project

```bash
cd ceramics-journal
brew install xcodegen
xcodegen generate
```

### 3. Run

1. Open `CeramicsJournal.xcodeproj`.
2. Select the **CeramicsJournal** scheme and an iPhone simulator.
3. Hit **Run (⌘R)**.

To run on a real iPhone: select your device, choose your (free) Apple ID
under *Signing & Capabilities*, and the app will install over USB.

> No `xcodegen` on the Mac? Create a new *iOS App* project in Xcode named
> `CeramicsJournal`, delete the files Xcode generated, and drag in the
> `CeramicsJournal/` folder from this repo. All logic is in source files —
> `project.yml` just assembles the project settings.

### 4. Tests

Select the **CeramicsJournalTests** scheme and press **⌘U**.
Covers shape geometry, image storage, and domain defaults.

---

## What's inside (MVP)

The complete MVP workflow from the spec works end-to-end:

```
Create clay → add fired photo → create glaze → add fired glaze photo
→ choose shape → create project → assign clay → assign glaze
→ choose glaze area → preview → construction journal
→ 1000°C bisque record → 1240°C glaze record → final photos
→ planned vs actual → evaluation → find it later via search
```

| Area | Details |
| --- | --- |
| **Tabs** | Home · Projects · Materials · Journal |
| **Home** | Global search, recent projects, material shortcuts, quick actions |
| **Projects** | List/grid, search, filters (status / clay / glaze / shape), sort, status workflow (Idea → Planned → In progress → Bisque → Glaze → Completed / Archived) |
| **New Project** | 5-step flow: Name & Shape → Clay → Glaze → Placement → Preview |
| **Preview** | Vector silhouettes (mug, cup, bowl, plate, vase, jar, planter, custom) + clay image/color fill + glaze layers with area masks (entire / interior / exterior / base / custom) and opacity. Always labeled **“Material reference preview”** — never a prediction |
| **Materials** | Clays / Glazes / Engobes libraries; photos (take or pick), firing ranges, finish & transparency, confidence: *Reference / Manufacturer data / User tested* |
| **Journal** | Chronological timeline (creation, construction entries, firings) grouped by day; entries with photos |
| **Firing** | Records with type, target/actual temps, kiln, atmosphere, result, photos; defaults: bisque 1000°C, glaze 1240°C |
| **Final result** | Planned vs Actual side-by-side + evaluation (worked / failed / surprises / next time / repeat? Yes-No-Maybe) |
| **Search & filters** | Global search across projects, materials, journal, firings and evaluation text |

### Core integrity rules (from the spec)

- **No invented results.** The preview is a composition of *your* saved
  references; the app never claims to predict fired color, runs, pooling or
  food safety.
- **History survives material deletion.** When a clay/glaze is deleted,
  projects keep a snapshot (name, manufacturer, fired image copy).
- **Four image kinds are never conflated:** Inspiration · Material reference ·
  Material reference preview · Actual result — each has its own colored tag.
- **Photos are first-class:** camera capture or photo-library import everywhere
  they matter; stored as files in Application Support (not SwiftData blobs).
- **Offline-first:** no network code anywhere.

---

## Project structure

```
ceramics-journal/
├── project.yml                  # XcodeGen spec (xcodegen generate)
├── CeramicsJournal/
│   ├── App/                     # @main + ModelContainer
│   ├── Theme/                   # Palette & reusable styles (cute cards, capsule buttons)
│   ├── Models/                  # SwiftData models + enums
│   ├── Services/
│   │   ├── ImageStore.swift     # save/load/delete/copy/average-color
│   │   ├── ShapeGeometry.swift  # silhouettes + glaze region masks
│   │   └── SeedData.swift       # predefined shapes
│   ├── Components/              # cards, badges, photo slot, camera
│   ├── Views/
│   │   ├── Home/  Projects/  Materials/  Shapes/  Pickers/
│   │   ├── Preview/             # PreviewCanvas + editor
│   │   ├── Journal/  Firing/  Result/
│   │   └── RootView.swift       # tab bar
└── CeramicsJournalTests/        # unit tests (geometry, image store, defaults)
```

## Notes & conventions

- The shape model is named `PieceShape` to avoid colliding with
  `SwiftUI.Shape`.
- Glaze "custom area" placement is described in words (e.g. *Dragon*) and
  rendered on a patch mask; freehand masks are a Phase 2 feature.
- Temperatures are stored as `Double` °C; the default studio profile is
  bisque 1000°C / glaze 1240°C, configurable per record.
