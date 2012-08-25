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

  def get_next_documents_from_field_value(value, field)
    terms = get_ordered_terms(value, field)
    get_solr_response_for_field_values(field, terms, :per_page=>terms.length).last.sort{|a,b| a[shelfkey_field] <=> b[shelfkey_field] }
  end

  def get_ordered_terms(value, field)
    solr_options = {
      :"terms.fl"         => field,
      :"terms.lower"      => value,
      :"terms.limit"      => total_terms
    }
    response = Blacklight.solr.send_and_receive("/solr#{BlacklightBrowseNearby::Engine.config.request_handler}", {:params=>solr_options})
    response["terms"][field].select{|term| term.is_a?(String) }[start_of_terms..(total_terms-1)]
  end

  def start_of_terms
    return 0 if normalized_page == 0
    total_terms - hits_requested
  end

  def total_terms
    return original_query_offset if normalized_page == 0
    (hits_requested * normalized_page) + original_query_offset
  end
  
  def hits_requested
    return BlacklightBrowseNearby::Engine.config.default_hits.to_i if @opts[:number].blank?
    @opts[:number].to_i
  end
  
  def original_query_offset
    (hits_requested - 1) / 2
  end
  
  def normalized_page
    return 0 if @opts[:page].blank?
    @opts[:page].to_s.gsub("-","").to_i
  end
  
  def potential_values
    @original_document[value_field]
  end
  
  def current_value
    get_value_from_combined_key(combined_key, value_field)
  end
  
  def combined_key
    return @original_document[combined_key_field].first if (@original_document[combined_key_field].length == 1 or @opts[:preferred_value].blank?)
    @original_document[combined_key_field].each do |key|
      return key if get_value_from_combined_key(key, value_field) == @opts[:preferred_value]
    end
  end
  
  def params
    @opts[:params] || {}
  end
    
  protected

  def document_has_required_fields?
    [value_field, reverse_shelfkey_field, shelfkey_field, combined_key_field].each do |field|
      return false if @original_document[field].blank?
    end
    true
  end

  def get_value_from_combined_key(key, field)
    index = BlacklightBrowseNearby::Engine.config.combined_key_pattern.split(delimiter).map{|p|p.strip}.index(field)
    key.split(delimiter)[index].strip
  end

  def value_field
    BlacklightBrowseNearby::Engine.config.value_field
  end

  def reverse_shelfkey_field
    BlacklightBrowseNearby::Engine.config.reverse_sortkey_field
  end

  def shelfkey_field
    BlacklightBrowseNearby::Engine.config.sortkey_field
  end

  def combined_key_field
    BlacklightBrowseNearby::Engine.config.combined_key_field
  end
  
  def delimiter
    BlacklightBrowseNearby::Engine.config.key_delimiter
  end
   
end