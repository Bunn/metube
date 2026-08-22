import Foundation
import WebKit

@MainActor
enum AdBlocker {
    private static let ruleListIdentifier = "MeTube.YouTubeRules.v3"

    static func installUserScripts(on controller: WKUserContentController) {
        let script = WKUserScript(
            source: pageWorldScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false,
            in: .page
        )
        controller.addUserScript(script)
    }

    static func installContentRules(on controller: WKUserContentController) async throws {
        guard let store = WKContentRuleListStore.default() else {
            throw AdBlockerError.ruleListStoreUnavailable
        }
        let list: WKContentRuleList

        if let existing = await lookup(identifier: ruleListIdentifier, in: store) {
            list = existing
        } else {
            list = try await compile(identifier: ruleListIdentifier, in: store)
        }

        controller.add(list)
    }

    private static func lookup(
        identifier: String,
        in store: WKContentRuleListStore
    ) async -> WKContentRuleList? {
        await withCheckedContinuation { continuation in
            store.lookUpContentRuleList(forIdentifier: identifier) { list, _ in
                // A missing identifier is reported as a lookup error on a first launch. Treat it
                // as a cache miss so the current rules are compiled below.
                continuation.resume(returning: list)
            }
        }
    }

    private static func compile(
        identifier: String,
        in store: WKContentRuleListStore
    ) async throws -> WKContentRuleList {
        try await withCheckedThrowingContinuation { continuation in
            store.compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: contentRules
            ) { list, error in
                if let list {
                    continuation.resume(returning: list)
                } else {
                    continuation.resume(throwing: error ?? AdBlockerError.compilationReturnedNoRules)
                }
            }
        }
    }

    private enum AdBlockerError: Error {
        case compilationReturnedNoRules
        case ruleListStoreUnavailable
    }

    private static let contentRules = #"""
    [
      {
        "trigger": {
          "url-filter": "doubleclick\\.net",
          "resource-type": ["script", "image", "style-sheet", "raw", "media", "font"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "googlesyndication\\.com",
          "resource-type": ["script", "image", "style-sheet", "raw", "media", "font"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "googleadservices\\.com",
          "resource-type": ["script", "image", "style-sheet", "raw", "media", "font"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "googletagservices\\.com",
          "resource-type": ["script", "image", "style-sheet", "raw", "media", "font"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "googletagmanager\\.com",
          "resource-type": ["script", "image", "style-sheet", "raw", "media", "font"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "youtube(-nocookie)?\\.com/api/stats/ads",
          "resource-type": ["image", "raw", "media"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "youtube(-nocookie)?\\.com/pagead/",
          "resource-type": ["image", "raw", "media"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "youtube(-nocookie)?\\.com/ptracking",
          "resource-type": ["image", "raw", "media"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "googlevideo\\.com/.*_ad_",
          "resource-type": ["media", "raw"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": "googlevideo\\.com/ad/",
          "resource-type": ["media", "raw"],
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"],
          "url-filter-is-case-sensitive": true
        },
        "action": { "type": "block" }
      },
      {
        "trigger": {
          "url-filter": ".*",
          "if-domain": ["*youtube.com", "*youtube-nocookie.com"]
        },
        "action": {
          "type": "css-display-none",
          "selector": "ytd-display-ad-renderer, ytd-promoted-sparkles-web-renderer, ytd-in-feed-ad-layout-renderer, ytd-ad-slot-renderer, ytm-promoted-sparkles-web-renderer, ytm-companion-ad-renderer, #player-ads, #masthead-ad, .video-ads, .ytp-ad-module, .ytp-ad-overlay-container"
        }
      }
    ]
    """#

    /// A compact, YouTube-specific subset of the response-pruning approach used by modern
    /// blockers. It intentionally avoids a generic filter engine and continuous DOM scanning.
    private static let pageWorldScript = #"""
    (() => {
      'use strict';

      const hostname = location.hostname.toLowerCase();
      if (!(hostname === 'youtu.be' || hostname.endsWith('.youtube.com') ||
            hostname === 'youtube.com' || hostname.endsWith('.youtube-nocookie.com') ||
            hostname === 'youtube-nocookie.com')) {
        return;
      }

      const removableKeys = new Set([
        'adPlacements',
        'playerAds',
        'adSlots',
        'adBreakHeartbeatParams',
        'adBreakParams'
      ]);

      const prune = (root) => {
        if (root === null || typeof root !== 'object') return root;
        const visited = new WeakSet();

        const walk = (value, depth) => {
          if (depth > 18 || value === null || typeof value !== 'object' || visited.has(value)) return;
          visited.add(value);

          if (Array.isArray(value)) {
            for (let index = value.length - 1; index >= 0; index -= 1) {
              const item = value[index];
              const isShortAd = item && typeof item === 'object' &&
                item.command && item.command.reelWatchEndpoint &&
                item.command.reelWatchEndpoint.adClientParams &&
                item.command.reelWatchEndpoint.adClientParams.isAd;
              if (isShortAd) {
                value.splice(index, 1);
              } else {
                walk(item, depth + 1);
              }
            }
            return;
          }

          for (const key of Object.keys(value)) {
            if (removableKeys.has(key)) {
              try { delete value[key]; } catch (_) {}
            } else {
              walk(value[key], depth + 1);
            }
          }
        };

        walk(root, 0);
        return root;
      };

      const mayContainAds = (text) => typeof text === 'string' && text.length > 256 &&
        (text.includes('"adPlacements"') || text.includes('"playerAds"') ||
         text.includes('"adSlots"') || text.includes('"adBreakHeartbeatParams"'));

      const nativeJSONParse = JSON.parse;
      JSON.parse = new Proxy(nativeJSONParse, {
        apply(target, thisArgument, argumentsList) {
          const result = Reflect.apply(target, thisArgument, argumentsList);
          return mayContainAds(argumentsList[0]) ? prune(result) : result;
        }
      });

      let initialPlayerResponse;
      try {
        Object.defineProperty(window, 'ytInitialPlayerResponse', {
          configurable: true,
          enumerable: true,
          get: () => initialPlayerResponse,
          set: (value) => { initialPlayerResponse = prune(value); }
        });
      } catch (_) {}

      const playerEndpoint = /\/(youtubei\/v1\/player|youtubei\/v1\/get_watch|playlist|watch)(\?|$)/;
      const nativeFetch = window.fetch;
      if (typeof nativeFetch === 'function') {
        window.fetch = new Proxy(nativeFetch, {
          async apply(target, thisArgument, argumentsList) {
            const response = await Reflect.apply(target, thisArgument, argumentsList);
            const request = argumentsList[0];
            const requestURL = typeof request === 'string' ? request : (request && request.url) || '';
            if (!playerEndpoint.test(requestURL)) return response;

            try {
              const text = await response.clone().text();
              if (!mayContainAds(text)) return response;
              const body = JSON.stringify(prune(nativeJSONParse(text)));
              const filtered = new Response(body, {
                status: response.status,
                statusText: response.statusText,
                headers: response.headers
              });
              try {
                Object.defineProperties(filtered, {
                  url: { value: response.url },
                  redirected: { value: response.redirected },
                  type: { value: response.type }
                });
              } catch (_) {}
              return filtered;
            } catch (_) {
              return response;
            }
          }
        });
      }

      const xhrPrototype = window.XMLHttpRequest && window.XMLHttpRequest.prototype;
      if (xhrPrototype) {
        const nativeOpen = xhrPrototype.open;
        const responseDescriptor = Object.getOwnPropertyDescriptor(xhrPrototype, 'response');
        const responseTextDescriptor = Object.getOwnPropertyDescriptor(xhrPrototype, 'responseText');
        const requestURLs = new WeakMap();
        const responseCache = new WeakMap();

        xhrPrototype.open = new Proxy(nativeOpen, {
          apply(target, thisArgument, argumentsList) {
            requestURLs.set(thisArgument, String(argumentsList[1] || ''));
            return Reflect.apply(target, thisArgument, argumentsList);
          }
        });

        if (responseDescriptor && responseDescriptor.get) {
          try {
            Object.defineProperty(xhrPrototype, 'response', {
              configurable: true,
              enumerable: responseDescriptor.enumerable,
              get: function() {
                const original = responseDescriptor.get.call(this);
                if (this.readyState !== 4 || !playerEndpoint.test(requestURLs.get(this) || '')) return original;
                if (responseCache.has(this)) return responseCache.get(this);

                try {
                  let filtered = original;
                  if (typeof original === 'string' && mayContainAds(original)) {
                    filtered = JSON.stringify(prune(nativeJSONParse(original)));
                  } else if (original && typeof original === 'object') {
                    filtered = prune(original);
                  }
                  responseCache.set(this, filtered);
                  return filtered;
                } catch (_) {
                  return original;
                }
              }
            });
          } catch (_) {}
        }

        if (responseTextDescriptor && responseTextDescriptor.get) {
          try {
            Object.defineProperty(xhrPrototype, 'responseText', {
              configurable: true,
              enumerable: responseTextDescriptor.enumerable,
              get: function() {
                const original = responseTextDescriptor.get.call(this);
                if (this.readyState !== 4 || !playerEndpoint.test(requestURLs.get(this) || '') || !mayContainAds(original)) {
                  return original;
                }
                try { return JSON.stringify(prune(nativeJSONParse(original))); } catch (_) { return original; }
              }
            });
          } catch (_) {}
        }
      }

      const style = document.createElement('style');
      style.textContent = `
        ytd-display-ad-renderer,
        ytd-promoted-sparkles-web-renderer,
        ytd-in-feed-ad-layout-renderer,
        ytd-ad-slot-renderer,
        ytm-promoted-sparkles-web-renderer,
        ytm-companion-ad-renderer,
        #player-ads,
        #masthead-ad,
        .video-ads,
        .ytp-ad-module,
        .ytp-ad-overlay-container { display: none !important; }
      `;
      (document.head || document.documentElement).appendChild(style);

      const clearAd = (player) => {
        if (!player || !player.classList.contains('ad-showing')) return;
        const skip = player.querySelector('.ytp-ad-skip-button-modern, .ytp-ad-skip-button, .ytp-skip-ad-button');
        if (skip) skip.click();
        const video = player.querySelector('video');
        if (video && Number.isFinite(video.duration) && video.duration > 0) {
          video.muted = true;
          video.currentTime = video.duration;
        }
      };

      let attempts = 0;
      const attachPlayerObserver = () => {
        const player = document.querySelector('#movie_player');
        if (!player) {
          attempts += 1;
          if (attempts < 12) setTimeout(attachPlayerObserver, Math.min(250 * attempts, 2000));
          return;
        }
        clearAd(player);
        new MutationObserver(() => {
          clearAd(player);
          if (player.classList.contains('ad-showing')) {
            setTimeout(() => clearAd(player), 80);
            setTimeout(() => clearAd(player), 300);
          }
        }).observe(player, { attributes: true, attributeFilter: ['class'] });
      };
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', attachPlayerObserver, { once: true });
      } else {
        attachPlayerObserver();
      }
    })();
    """#
}
