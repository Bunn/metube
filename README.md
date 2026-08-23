# MeTube

MeTube is a small native macOS YouTube viewer designed for older Intel Macs. It uses one `WKWebView`, a native macOS browser toolbar, and no third-party runtime dependencies.

## How playback works

1. Launch stays on a native start screen; no YouTube renderer is created until it is needed.
2. Optional browsing and search use YouTube's lighter mobile site.
3. In the default optimized mode, YouTube watch, Shorts, live, and `youtu.be` links are intercepted before the full watch page loads.
4. Playback moves into a small local HTML shell whose visible request is a `youtube-nocookie.com/embed` URL, following the core DuckPlayer design in the neighboring `apple-browsers` repository.
5. WebKit applies a compiled request rule list, page-world response pruning, cosmetic hiding, and a lightweight ad-skip fallback.

The response pruning targets the current YouTube player fields used by uBlock Origin's maintained filters: `adPlacements`, `playerAds`, `adSlots`, and related ad-break data. YouTube changes frequently, so ad blocking is best-effort and the small ruleset will need maintenance over time.

## Build and run

Requires macOS 13 or newer and Xcode command-line tools.

```sh
./script/build_and_run.sh
```

The default build is an optimized release build. Optional modes are `--verify`, `--debug`, `--logs`, and `--telemetry`. The staged app is written to `dist/MeTube.app`.

While a video is playing, use the menu-bar player button in the toolbar or press `⌥⌘M`. MeTube hides its main window and moves the same live player into a menu-bar popover, so playback continues when the popover is closed. Choose **Detach** for a movable, resizable, always-on-top PiP-style panel; choose **Attach to Menu Bar** to dock it back into the popover, or **Main Window** to restore the normal app window.

Open **MeTube → Settings…** (`⌘,`) to choose how the menu-bar popover dismisses and change playback mode. **Optimized player** minimizes CPU and memory use. **Full YouTube page** loads the normal watch page—including comments and recommendations—at a higher resource cost.

The native browser toolbar remains in the title bar so WebKit's video surface never needs to resize in response to pointer movement. YouTube's player fullscreen button is supported in both playback modes.

## iPhone and iPad

Open `iOS/MeTube-iOS.xcodeproj` in Xcode, select the **MeTube-iOS** scheme, and run it on an iPhone or iPad running iOS 17 or later. The iOS app uses the same YouTube URL parser, optimized player, full-page comments mode, and protection engine as the Mac app. Its native bottom browser controls stay outside the web content, and WebKit is configured for inline playback, system fullscreen, Picture in Picture, and AirPlay.

The iOS target uses the bundle identifier `dev.bunn.metube`. Signing remains automatic, so choose your development team in Xcode before installing it on a physical device.

## Design choices

- WebKit content rules compile to efficient bytecode and run in the networking/content pipeline.
- A single-site curated ruleset avoids shipping a large general-purpose filter engine and thousands of irrelevant filters.
- One persistent web view preserves YouTube cookies while avoiding a tab/process manager.
- The Mac web view identifies itself using the installed Safari major/minor version, with Safari 26 as a fallback.
- The menu-bar mini player reparents that same web view instead of starting another stream or reloading the video.
- Optimized playback uses the privacy-enhanced embed surface instead of YouTube's much heavier desktop watch page; full-page playback is available when comments are more important than efficiency.
- No polling loop scans the whole DOM; the fallback observes only the player class while an ad is showing.

## Research sources

- [DuckDuckGo Apple browser](https://github.com/duckduckgo/apple-browsers) — DuckPlayer architecture and WebKit integration.
- [uBlock Origin engine](https://github.com/gorhill/uBlock) and [uAssets YouTube filters](https://github.com/uBlockOrigin/uAssets/blob/master/filters/filters.txt) — network, cosmetic, and response/scriptlet filtering model.
- [Brave adblock-rust](https://github.com/brave/adblock-rust) and [Brave Core](https://github.com/brave/brave-core/tree/master/components/brave_shields) — compiled filter sets, resource injection, serialization, and platform integration.
- [WebKit content blocker design](https://webkit.org/blog/3476/content-blockers-first-look/) — native compiled rule behavior and performance guidance.

This project is independent of YouTube, Google, DuckDuckGo, uBlock Origin, and Brave.
