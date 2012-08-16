# re-thinking config names to be something more like sort_field, reverse_sort_field
BlacklightBrowseNearby::Engine.config.shelfkey             = "shelfkey"
BlacklightBrowseNearby::Engine.config.reverse_shelfkey     = "reverse_shelfkey"
BlacklightBrowseNearby::Engine.config.combined_key         = "combined_shelfkey"
BlacklightBrowseNearby::Engine.config.key_delimiter        = "-|-"
BlacklightBrowseNearby::Engine.config.combined_key_pattern = "callnumber #{BlacklightBrowseNearby::Engine.config.key_delimiter} #{BlacklightBrowseNearby::Engine.config.shelfkey} #{BlacklightBrowseNearby::Engine.config.key_delimiter} #{BlacklightBrowseNearby::Engine.config.reverse_shelfkey}"
BlacklightBrowseNearby::Engine.config.request_handler      = "alpha_terms"
BlacklightBrowseNearby::Engine.config.default_hits         = "10"