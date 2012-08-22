# -*- encoding : utf-8 -*-
module BlacklightBrowseNearby::CatalogExtension
  extend ActiveSupport::Concern
  include ActionView::Helpers::CaptureHelper
  include ActionView::Context
  
  included do
    before_filter :blacklight_browse_nearby, :only => :show
  end
  
  protected  
  def blacklight_browse_nearby
    @blacklight_browse_nearby_items = BlacklightBrowseNearby.new(params[:id]).documents
  end
end