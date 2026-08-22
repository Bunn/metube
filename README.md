# MeTube

MeTube is a small native macOS YouTube viewer designed for older Intel Macs. It uses one `WKWebView`, a native SwiftUI toolbar, and no third-party runtime dependencies.

## How playback works

1. Launch stays on a native start screen; no YouTube renderer is created until it is needed.
2. Optional browsing and search use YouTube's lighter mobile site.
3. YouTube watch, Shorts, live, and `youtu.be` links are intercepted before the full watch page loads.
4. Playback moves into a small local HTML shell whose visible request is a `youtube-nocookie.com/embed` URL, following the core DuckPlayer design in the neighboring `apple-browsers` repository.
5. WebKit applies a compiled request rule list, page-world response pruning, cosmetic hiding, and a lightweight ad-skip fallback.

The response pruning targets the current YouTube player fields used by uBlock Origin's maintained filters: `adPlacements`, `playerAds`, `adSlots`, and related ad-break data. YouTube changes frequently, so ad blocking is best-effort and the small ruleset will need maintenance over time.

## Build and run

Requires macOS 13 or newer and Xcode command-line tools.

```sh
./script/build_and_run.sh
```

The default build is an optimized release build. Optional modes are `--verify`, `--debug`, `--logs`, and `--telemetry`. The staged app is written to `dist/MeTube.app`.

While a video is playing, use the menu-bar player button in the toolbar or press `⌥⌘M`. MeTube hides its main window and moves the same live player into a menu-bar popover, so playback continues when the popover is closed. Choose **Return to Window** in the popover to restore the normal app window.

## Design choices

- WebKit content rules compile to efficient bytecode and run in the networking/content pipeline.
- A single-site curated ruleset avoids shipping a large general-purpose filter engine and thousands of irrelevant filters.
- One persistent web view preserves YouTube cookies while avoiding a tab/process manager.
- The menu-bar mini player reparents that same web view instead of starting another stream or reloading the video.
- Playback uses the privacy-enhanced embed surface instead of YouTube's much heavier desktop watch page.
- No polling loop scans the whole DOM; the fallback observes only the player class while an ad is showing.

## Research sources

- [DuckDuckGo Apple browser](https://github.com/duckduckgo/apple-browsers) — DuckPlayer architecture and WebKit integration.
- [uBlock Origin engine](https://github.com/gorhill/uBlock) and [uAssets YouTube filters](https://github.com/uBlockOrigin/uAssets/blob/master/filters/filters.txt) — network, cosmetic, and response/scriptlet filtering model.
- [Brave adblock-rust](https://github.com/brave/adblock-rust) and [Brave Core](https://github.com/brave/brave-core/tree/master/components/brave_shields) — compiled filter sets, resource injection, serialization, and platform integration.
- [WebKit content blocker design](https://webkit.org/blog/3476/content-blockers-first-look/) — native compiled rule behavior and performance guidance.

This project is independent of YouTube, Google, DuckDuckGo, uBlock Origin, and Brave.
