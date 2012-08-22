require "blacklight"
require "blacklight_browse_nearby/engine"
require "blacklight_browse_nearby_config"
class BlacklightBrowseNearby
  autoload :CatalogExtension, "blacklight/catalog_extension"
  
  include Blacklight::SolrHelper
  include Blacklight::Configurable
  def blacklight_config
    @config = Blacklight::Configuration.new
    @config
  end
  def params; {}; end
  
  attr_reader :documents
  def initialize(object_id, options={})
    @opts = options
    @documents = get_nearby_documents(object_id)
  end

  def get_nearby_documents(id)
    original_doc = get_solr_response_for_doc_id(id).last # returns an array with a response object and the document.
    combined_key = get_combined_key(original_doc[combined_key_field])
    shelfkey = get_value_from_combined_key(combined_key, shelfkey_field)
    reverse_shelfkey = get_value_from_combined_key(combined_key, reverse_shelfkey_field)
    if normalized_page == 0
      previous_documents = get_next_documents_from_field_value(reverse_shelfkey, reverse_shelfkey_field)
      current_document = original_doc
      next_documents = get_next_documents_from_field_value(shelfkey, shelfkey_field)
      documents = [previous_documents, current_document, next_documents].flatten
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
  
  protected

  def get_combined_key(combined_keys)
    return combined_keys.first if (combined_keys.length == 1 or !@opts.has_key?(:preferred_value))
    combined_keys.each do |key|
      return key if key.split(delimiter).map{|k|k.strip}.include?(@opts[:preferred_value])
    end
  end

  def get_value_from_combined_key(key, field)
    index = BlacklightBrowseNearby::Engine.config.combined_key_pattern.split(delimiter).map{|p|p.strip}.index(field)
    key.split(delimiter)[index].strip
  end

  def reverse_shelfkey_field
    BlacklightBrowseNearby::Engine.config.reverse_shelfkey
  end

  def shelfkey_field
    BlacklightBrowseNearby::Engine.config.shelfkey
  end

  def combined_key_field
    BlacklightBrowseNearby::Engine.config.combined_key
  end
  
  def delimiter
    BlacklightBrowseNearby::Engine.config.key_delimiter
  end
   
end