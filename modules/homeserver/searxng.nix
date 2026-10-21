{ lib, ... }: {
  options.homeserver.searxng = lib.mkOption { type = lib.types.deferredModule; };

  config.homeserver.searxng = { config, ... }: {
    age.secrets.searxng-secret-key = {
      file = ../../secrets/searxng-secret-key.age;
      owner = "searx";
    };

    services.searx = {
      enable = true;
      environmentFile = config.age.secrets.searxng-secret-key.path;
      settings = {
        server = {
          port = 8095;
          bind_address = "0.0.0.0"; # must be reachable from the VPS over tailscale
          secret_key = "$SEARX_SECRET_KEY";
          method = "POST";
          image_proxy = true;
          query_in_title = false;
        };

        ui = {
          center_alignment = true;
          results_on_new_tab = true;
        };

        plugins."searx.plugins.oa_doi_rewrite.SXNGPlugin".active = true;
        plugins."searx.plugins.infinite_scroll.SXNGPlugin".active = true;

        # Off entirely: Social media, Files, Science, IT, Music categories.
        # Explicit on/off within News/Videos/Images/General per user selection.
        engines = [
          { name = "1337x"; disabled = true; }
          { name = "9gag"; disabled = true; }
          { name = "adobe stock audio"; disabled = true; }
          { name = "alpine linux packages"; disabled = true; }
          { name = "anaconda"; disabled = true; }
          { name = "annas archive"; disabled = true; }
          { name = "apk mirror"; disabled = true; }
          { name = "apple app store"; disabled = true; }
          { name = "arch linux wiki"; disabled = true; }
          { name = "artic"; disabled = true; }
          { name = "arxiv"; disabled = true; }
          { name = "askubuntu"; disabled = true; }
          { name = "baidu kaifa"; disabled = true; }
          { name = "bandcamp"; disabled = true; }
          { name = "bing images"; disabled = true; }
          { name = "bing videos"; disabled = true; }
          { name = "bitbucket"; disabled = true; }
          { name = "boardreader"; disabled = false; }
          { name = "brave"; disabled = true; }
          { name = "brave.images"; disabled = true; }
          { name = "brave.videos"; disabled = true; }
          { name = "bt4g"; disabled = true; }
          { name = "btdigg"; disabled = true; }
          { name = "cachy os packages"; disabled = true; }
          { name = "caddy.community"; disabled = true; }
          { name = "codeberg"; disabled = true; }
          { name = "crates.io"; disabled = true; }
          { name = "crossref"; disabled = true; }
          { name = "dailymotion"; disabled = true; }
          { name = "ddg definitions"; disabled = false; }
          { name = "deezer"; disabled = true; }
          { name = "discuss.python"; disabled = true; }
          { name = "docker hub"; disabled = true; }
          { name = "encyclosearch"; disabled = false; }
          { name = "fdroid"; disabled = true; }
          { name = "flickr"; disabled = true; }
          { name = "free software directory"; disabled = true; }
          { name = "fynd"; disabled = false; }
          { name = "genius"; disabled = true; }
          { name = "gentoo"; disabled = true; }
          { name = "gitea.com"; disabled = true; }
          { name = "github"; disabled = true; }
          { name = "gitlab"; disabled = true; }
          { name = "gmx"; disabled = false; }
          { name = "google play apps"; disabled = true; }
          { name = "google scholar"; disabled = true; }
          { name = "habrahabr"; disabled = true; }
          { name = "hackernews"; disabled = true; }
          { name = "hex"; disabled = true; }
          { name = "hoogle"; disabled = true; }
          { name = "huggingface"; disabled = true; }
          { name = "huggingface datasets"; disabled = true; }
          { name = "huggingface spaces"; disabled = true; }
          { name = "kickass"; disabled = true; }
          { name = "lemmy comments"; disabled = true; }
          { name = "lemmy communities"; disabled = true; }
          { name = "lemmy posts"; disabled = true; }
          { name = "lemmy users"; disabled = true; }
          { name = "library genesis"; disabled = true; }
          { name = "lib.rs"; disabled = true; }
          { name = "lobste.rs"; disabled = true; }
          { name = "mankier"; disabled = true; }
          { name = "mastodon hashtags"; disabled = true; }
          { name = "mastodon users"; disabled = true; }
          { name = "mdn"; disabled = true; }
          { name = "metacpan"; disabled = true; }
          { name = "microsoft learn"; disabled = true; }
          { name = "mixcloud"; disabled = true; }
          { name = "mojeek"; disabled = false; }
          { name = "mojeek news"; disabled = false; }
          { name = "mozhi"; disabled = false; }
          { name = "mwmbl"; disabled = false; }
          { name = "national vulnerability database"; disabled = true; }
          { name = "nixos wiki"; disabled = true; }
          { name = "npm"; disabled = true; }
          { name = "nyaa"; disabled = true; }
          { name = "odysee"; disabled = false; }
          { name = "ollama"; disabled = true; }
          { name = "openairedatasets"; disabled = true; }
          { name = "openairepublications"; disabled = true; }
          { name = "openalex"; disabled = true; }
          { name = "openlibrary"; disabled = false; }
          { name = "openrepos"; disabled = true; }
          { name = "packagist"; disabled = true; }
          { name = "pdbe"; disabled = true; }
          { name = "peertube"; disabled = false; }
          { name = "pi-hole.community"; disabled = true; }
          { name = "piratebay"; disabled = true; }
          { name = "pixabay images"; disabled = false; }
          { name = "pixabay videos"; disabled = false; }
          { name = "pkg.go.dev"; disabled = true; }
          { name = "presearch"; disabled = false; }
          { name = "presearch news"; disabled = false; }
          { name = "pub.dev"; disabled = true; }
          { name = "public domain image archive"; disabled = false; }
          { name = "pubmed"; disabled = true; }
          { name = "pypi"; disabled = true; }
          { name = "qwant"; disabled = false; }
          { name = "radio browser"; disabled = true; }
          { name = "reddit"; disabled = true; }
          { name = "rubygems"; disabled = true; }
          { name = "semantic scholar"; disabled = true; }
          { name = "solidtorrents"; disabled = true; }
          { name = "soundcloud"; disabled = true; }
          { name = "sourcehut"; disabled = true; }
          { name = "stackoverflow"; disabled = true; }
          { name = "superuser"; disabled = true; }
          { name = "tineye"; disabled = false; }
          { name = "tokyotoshokan"; disabled = true; }
          { name = "tootfinder"; disabled = true; }
          { name = "vimeo"; disabled = true; }
          { name = "voidlinux"; disabled = true; }
          { name = "wiby"; disabled = false; }
          { name = "wikicommons.audio"; disabled = true; }
          { name = "wikicommons.files"; disabled = true; }
          { name = "wikispecies"; disabled = true; }
          { name = "yacy"; disabled = false; }
          { name = "yacy images"; disabled = false; }
          { name = "yandex images"; disabled = false; }
          { name = "yandex music"; disabled = true; }
          { name = "youtube"; disabled = true; }
        ];
      };
    };
  };
}
