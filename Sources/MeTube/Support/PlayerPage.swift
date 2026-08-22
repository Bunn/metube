import Foundation

enum PlayerPage {
    static func html(for video: YouTubeVideo) -> String {
        let source = video.embedURL.absoluteString
        return #"""
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="color-scheme" content="dark">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; frame-src https://www.youtube-nocookie.com; style-src 'unsafe-inline'">
          <title>MeTube Player</title>
          <style>
            :root { color-scheme: dark; background: #000; }
            html, body, iframe { width: 100%; height: 100%; margin: 0; border: 0; overflow: hidden; background: #000; }
          </style>
        </head>
        <body>
          <iframe
            src="\#(source)"
            title="YouTube video player"
            allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
            referrerpolicy="strict-origin-when-cross-origin"
            allowfullscreen>
          </iframe>
        </body>
        </html>
        """#
    }
}
