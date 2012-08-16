class BlacklightBrowseNearbyController < ApplicationController
  include Blacklight::Catalog
  def index
    @response, @original_doc = get_solr_response_for_doc_id(params[:start])
    save_current_search_params
    @document_list = BlacklightBrowseNearby.new(:combined_field => @original_doc[BlacklightBrowseNarby::Engine.config.combined_key.to_sym],:field_value=>params[:field_value], :before => 9, :after => 10, :page => params[:page]).items
    render "catalog/_gallery_list"
  end
  
  def nearby
    @nearby_response = BlacklightBrowseNearby.new(:combined_field=>params[BlacklightBrowseNarby::Engine.config.combined_key.to_sym],:field_value=>params[:field_value], :before => 2, :after => 2)
    render :layout => false
  end
  
end