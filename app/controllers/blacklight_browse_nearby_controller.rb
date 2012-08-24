class BlacklightBrowseNearbyController < ApplicationController
  include Blacklight::Catalog
  
  before_filter :append_blacklight_catalog_view_context
  
  def index
    options = {}
    options[:page] = params[:page] if params[:page]
    options[:number] = params[:per_page] if params[:per_page]
    options[:preferred_value] = params[:preferred_value] if params[:preferred_value]
    @nearby = BlacklightBrowseNearby.new(params[:start], options)
    @document_list = @nearby.documents
    respond_to do |format|
      format.html{ save_current_search_params }
      format.js
    end

  end
  
  protected
  
  def append_blacklight_catalog_view_context
    self.view_context.lookup_context.prefixes << "catalog"
  end
end