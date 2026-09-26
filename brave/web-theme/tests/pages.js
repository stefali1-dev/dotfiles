// Pages each site is tested on.
// surface: the element whose background must be the theme's background.
// ignore: elements allowed to keep a neutral dark background (video players, images).
module.exports = {
  youtube: {
    surface: "ytd-app",
    ignore: ["#movie_player", "ytd-player", "ytd-video-preview", "#full-bleed-container"],
    pages: {
      home: "https://www.youtube.com/",
      watch: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      search: "https://www.youtube.com/results?search_query=omarchy",
    },
  },
  chatgpt: {
    surface: "body",
    pages: {
      home: "https://chatgpt.com/",
      chat: "https://chatgpt.com/c/6ab78075-46e8-83eb-99c8-9a077074768e",
    },
  },
  github: {
    surface: "body",
    pages: {
      dashboard: "https://github.com/",
      repo: "https://github.com/basecamp/omarchy",
      file: "https://github.com/basecamp/omarchy/blob/quattro/bin/omarchy-update",
      diff: "https://github.com/basecamp/omarchy/pull/13323/files",
    },
  },
  x: {
    surface: "body",
    ignore: ["video", '[data-testid="tweetPhoto"]'],
    pages: {
      home: "https://x.com/home",
      profile: "https://x.com/dhh",
      post: "https://x.com/GergelyOrosz/status/2103420272942498231",
    },
  },
  grok: {
    surface: "body",
    ignore: ["#onetrust-consent-sdk"],
    pages: {
      home: "https://grok.com/",
      chat: "https://grok.com/c/6b34c9c2-86a7-4788-903b-b9c574fe0a55",
    },
  },
};
