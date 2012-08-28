require "blacklight"
require "blacklight_browse_nearby/engine"
require "blacklight_browse_nearby_config"
class BlacklightBrowseNearby
  
  autoload :Controller, "blacklight_browse_nearby/controller"
    
  include Blacklight::SolrHelper
  include Blacklight::Configurable
    
  attr_reader :documents, :original_document
  def initialize(object_id, options={})
    @opts = options
    @documents = get_nearby_documents(object_id)
  end

  # Returns an array of documents "nearby" the given object ID based on page number.
  # Negative page numbers will return documents "behind" the given object ID.
  # No page number (or 0) will return documents "behind" the given object ID, the given object, and documents "in front of" the given object ID.
  # Positive page numbers will return documents "in front of" the given object ID.
  def get_nearby_documents(id)
    @original_document = get_solr_response_for_doc_id(id).last # returns an array with a response object and the document.
    return [] unless document_has_required_fields?
    shelfkey = get_value_from_combined_key(combined_key, shelfkey_field)
    reverse_shelfkey = get_value_from_combined_key(combined_key, reverse_shelfkey_field)
    if normalized_page == 0
      previous_documents = get_next_documents_from_field_value(reverse_shelfkey, reverse_shelfkey_field)
      next_documents = get_next_documents_from_field_value(shelfkey, shelfkey_field)
      documents = [previous_documents, @original_document, next_documents].flatten
    elsif @opts[:page].to_i < 0
      documents = get_next_documents_from_field_value(reverse_shelfkey, reverse_shelfkey_field)
    elsif @opts[:page].to_i > 0
      documents = get_next_documents_from_field_value(shelfkey, shelfkey_field)
    end
    documents
  end


  # Returns an array of documents forward of the given term in the given field. These documents are sorted by the configured solr field.
  # Using solr's termsComponent we request the next terms from the given field and value. This works for backward sorting by using a reverse-sort keys.
  # We then request the documents for those terms from solr via Blacklight's get_solr_response_for_field_values
  def get_next_documents_from_field_value(value, field)
    terms = get_ordered_terms(value, field)
    get_solr_response_for_field_values(field, terms, :per_page=>terms.length).last.sort{|a,b| a[shelfkey_field] <=> b[shelfkey_field] }
  end

  # Returns an array of the next terms using solr's termsComponent.
  # The number of terms requested/returned from solr may be much larger than what is returned by this method when paging.
  # The pagination happens here and we paginate the returned terms before we request the related documents. This keeps the URLs free of sortkey values.
  def get_ordered_terms(value, field)
    solr_options = {
      :"terms.fl"         => field,
      :"terms.lower"      => value,
      :"terms.limit"      => total_terms
    }
    response = Blacklight.solr.send_and_receive("#{BlacklightBrowseNearby::Engine.config.request_handler}", {:params=>solr_options})
    response["terms"][field].select{|term| term.is_a?(String) }[start_of_terms..(total_terms-1)]
  end

  # Returns an integer representing the beginning of the range of terms we'll request documents for.
  def start_of_terms
    return 0 if normalized_page == 0
    total_terms - hits_requested
  end

  # Returns an integer representing the total number of terms to request from solr.
  def total_terms
    return original_query_offset if normalized_page == 0
    (hits_requested * normalized_page) + original_query_offset
  end
  
  # Returns an integer representing the number of terms that were requested. Falls back to the provided configuration option in BlacklightBrowseNearby::Engine.config.default_hits
  def hits_requested
    return BlacklightBrowseNearby::Engine.config.default_hits.to_i if @opts[:number].blank?
    @opts[:number].to_i
  end
  
  # Returns an integer representing the number of items that would have been intitally requested from page 0.  This is necessary to get the appropriate total_terms integer.
  def original_query_offset
    (hits_requested - 1) / 2
  end
  
  # Returns an integer representing a normalized page number.
  # This method will return a 0 in the absense of a page option and will turn any negative integer into a positive integer.
  def normalized_page
    return 0 if @opts[:page].blank?
    @opts[:page].to_s.gsub("-","").to_i
  end
  
  # Convenience method to return the value field from the original document. This is necessary for supportin the multi-valued field UI.
  def potential_values
    @original_document[value_field]
  end
  
  # Convenience method to return the value from the original document that is preferred_value aware. This is necessary for supporting the multi-valued field UI.
  def current_value
    get_value_from_combined_key(combined_key, value_field)
  end
  
  # Convenience method to return the combined key from the original document that is preferred_value aware. This is necessary for supporting multi-valued fields.
  def combined_key
    return @original_document[combined_key_field].first if (@original_document[combined_key_field].length == 1 or @opts[:preferred_value].blank?)
    @original_document[combined_key_field].each do |key|
      return key if get_value_from_combined_key(key, value_field) == @opts[:preferred_value]
    end
  end
  
  # Returns a hash that will be used by BlacklightSolrHelper.
  # The params hash can be passed in as an option on initialization (although the code isn't currently doing that).
  def params
    @opts[:params] || {}
  end
    
  protected

  # Returns a boolean validating that the given document has all the required fields for the browsing.
  def document_has_required_fields?
    [value_field, reverse_shelfkey_field, shelfkey_field, combined_key_field].each do |field|
      return false if @original_document[field].blank?
    end
    true
  end
  
  # Returns a string value from a given combined key and field name.
  # This takes advantage of the combined_key_pattern field to determine field position in the combined_key value.
  def get_value_from_combined_key(key, field)
    index = BlacklightBrowseNearby::Engine.config.combined_key_pattern.split(delimiter).map{|p|p.strip}.index(field)
    key.split(delimiter)[index].strip
  end

  # Convenience method to return a configuration option.
  def value_field
    BlacklightBrowseNearby::Engine.config.value_field
  end

  # Convenience method to return a configuration option.
  def reverse_shelfkey_field
    BlacklightBrowseNearby::Engine.config.reverse_sortkey_field
  end

  # Convenience method to return a configuration option.
  def shelfkey_field
    BlacklightBrowseNearby::Engine.config.sortkey_field
  end

  # Convenience method to return a configuration option.
  def combined_key_field
    BlacklightBrowseNearby::Engine.config.combined_key_field
  end
  
  # Convenience method to return a configuration option.
  def delimiter
    BlacklightBrowseNearby::Engine.config.key_delimiter
  end
   
end