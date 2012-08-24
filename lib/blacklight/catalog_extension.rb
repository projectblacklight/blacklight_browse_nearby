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
    @nearby = BlacklightBrowseNearby.new(params[:id])
    @blacklight_browse_nearby_items = @nearby.documents
  end
end