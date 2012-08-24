# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'     
class BlacklightBrowseNearbyGenerator < Rails::Generators::Base

    desc """
  This generator makes the following changes to your application:
   1. Adds Controller behavior to the application's Blacklight generated CatalogController.
   2. Adds a line in your application.css and application.js to load the BlacklightBrowseNearby assets
         """ 

    # Add BlacklightBrowseNearby::CatalogExtension to the application's Blacklight generated CatalogController.
    def inject_blacklight_browse_nearby_controller_behavior   
      unless IO.read("app/controllers/catalog_controller.rb").include?("BlacklightBrowseNearby::CatalogExtension")
        inject_into_class "app/controllers/catalog_controller.rb", "CatalogController" do
          "  # Adds a before filter to load nearby items\n" +        
          "  include BlacklightBrowseNearby::Controller\n\n"
        end
      end
    end
  
    # insert require statements into application level CSS/JS manifestes.
    def inject_blacklight_browse_nearby_require
      unless IO.read("app/assets/stylesheets/application.css").include?("Required by BlacklightBrowseNearby")
        insert_into_file "app/assets/stylesheets/application.css", :after => "/*" do
  %q{
 * Required by BlacklightBrowseNearby:
 *= require blacklight_browse_nearby/blacklight_browse_nearby
 *}
        end
      end
      unless IO.read("app/assets/javascripts/application.js").include?("Required by BlacklightBrowseNearby")
        insert_into_file "app/assets/javascripts/application.js", :before => "//= require_tree ." do
%q{// Required by BlacklightBrowseNearby:
//= require blacklight_browse_nearby/blacklight_browse_nearby
}
        end
      end
    end
    
    
end
