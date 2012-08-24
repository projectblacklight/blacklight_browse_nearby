# re-thinking config names to be something more like sort_field, reverse_sort_field
BlacklightBrowseNearby::Engine.config.value_field                 = "callnumber"
BlacklightBrowseNearby::Engine.config.sortkey_field               = "shelfkey"
BlacklightBrowseNearby::Engine.config.reverse_sortkey_field       = "reverse_shelfkey"
BlacklightBrowseNearby::Engine.config.combined_key_field          = "combined_shelfkey"
BlacklightBrowseNearby::Engine.config.key_delimiter               = "-|-"
BlacklightBrowseNearby::Engine.config.combined_key_pattern        = "#{BlacklightBrowseNearby::Engine.config.value_field} #{BlacklightBrowseNearby::Engine.config.key_delimiter} #{BlacklightBrowseNearby::Engine.config.sortkey_field} #{BlacklightBrowseNearby::Engine.config.key_delimiter} #{BlacklightBrowseNearby::Engine.config.reverse_sortkey_field}"
BlacklightBrowseNearby::Engine.config.request_handler             = "/alphaTerms"
BlacklightBrowseNearby::Engine.config.default_hits                = "5"
BlacklightBrowseNearby::Engine.config.full_view_default_hits      = "11"
BlacklightBrowseNearby::Engine.config.nearby_fields               = [BlacklightBrowseNearby::Engine.config.value_field]
BlacklightBrowseNearby::Engine.config.link_field                  = :title_display