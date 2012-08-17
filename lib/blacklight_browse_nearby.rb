require "blacklight"
require "blacklight_browse_nearby/engine"
require "blacklight_browse_nearby_config"
class BlacklightBrowseNearby
  include Blacklight::SolrHelper
  attr_reader :documents, :start_of_hits, :total_hits
  def initialize(object_id, options={})
    @opts = options
    @documents = get_nearby_documents(object_id)
  end

  def get_nearby_documents(id)
    original_doc = get_solr_response_for_doc_id(id).last # returns an array with a response object and the document.
    combined_key = get_combined_key(original_doc[combined_key_field])
    shelfkey = get_value_from_combined_key(combined_key, shelfkey_field)
    reverse_shelfkey = get_value_from_combined_key(combined_key, reverse_shelfkey_field)

    previous_documents = get_next_documents_from_field_value(reverse_shelfkey, reverse_shelfkey_field)
    current_document = original_doc
    next_documents = get_next_documents_from_field_value(shelfkey, shelfkey_field)
    [previous_documents, current_document, next_documents].flatten
  end

  def get_next_documents_from_field_value(value, field)
    terms = get_ordered_terms(value, field)
    get_solr_response_for_field_values(terms, field).last # returns an array with a response object and the document.
  end

  def get_ordered_terms(value, field)
    solr_options = {
      :"terms.fl"    => field,
      :"terms.lower" => value,
      :"terms.sort"  => "index",
      :"terms.limit" => total_hits,
      :"qt"          => BlacklightBrowseNearby::Engine.config.request_handler
    }
    response = Blacklight.solr.find(solr_options)
    response["terms"][field].select{|term| term.is_a?(String) }[start_of_hits..(total_hits-1)]
  end

  def start_of_hits
    starting_number = @opts.has_key?(:number) ? @opts[:number].to_i : (BlacklightBrowseNearby::Engine.config.default_hits.to_i - 1) / 2
    if @opts.has_key?(:page) and @opts[:page].to_i > 0
      return starting_number * @opts[:page].to_i
    else
      return 0
    end
  end

  def total_hits
    starting_number = @opts.has_key?(:number) ? @opts[:number].to_i : (BlacklightBrowseNearby::Engine.config.default_hits.to_i - 1) / 2
    if @opts.has_key?(:page) and @opts[:page].to_i > 0
      return starting_number * (@opts[:page].to_i+1)
    else
      return starting_number
    end
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