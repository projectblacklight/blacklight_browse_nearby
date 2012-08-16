require "blacklight_browse_nearby/engine"

class BlacklightBrowseNearby
  include Blacklight::SolrHelper
  attr_reader :items
  def initialize(object_id, options={})
    @opts = options
    @items = get_nearby_documents(object_id)
  end

  def get_nearby_documents(id)
    original_doc = get_solr_response_for_doc_id(id)
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
    # this is the only method that is called from Blacklight.
    get_solr_response_for_field_values(terms, field)
  end

  def get_ordered_terms(value, field)
    solr_options = {
      :"terms.fl"    => field,
      :"terms.lower" => value,
      :"terms.sort"  => "index",
      :"terms.limit" => number_of_hits,
      :"qt"          => BlacklightBrowseNearby::Engine.config.request_handler
    }
    response = Blacklight.solr.find(solr_options)
    response["terms"]["field"].map{|f| f if f.is_a?(String) }.compact[start_of_hits..total_hits]
  end

  def start_of_hits
    starting_number = @opts.has_key?(:number) ? @opts[:number].to_i : (BlacklightBrowseNearby::Engine.config.default_hits.to_i - 1) / 2
    if @opts.has_key?(:page) and @opts[:page] > 0
      return starting_number * @opts[:page].to_i
    else
      return 0
    end
  end

  def total_hits
    starting_number = @opts.has_key?(:number) ? @opts[:number].to_i : (BlacklightBrowseNearby::Engine.config.default_hits.to_i - 1) / 2
    if @opts.has_key?(:page) and @opts[:page] > 0
      return starting_number * (@opts[:page].to_i+1)
    else
      return starting_number
    end
  end

  def get_combined_key(combined_keys)
    return combined_keys.first if (combined_keys.length == 1 or !@opts.has_key?(:preferred_value))
    combined_keys.each do |key|
      return key if key.split(delimiter).map{|k|k.strip}.include?(@opts[:preferred_value])
    end
  end

  def get_value_from_combined_key(key, field)
    index = BlacklightBrowseNearby::Engine.config.combined_key_pattern.split(delimiter).map{|p|p.strip}.index(field)
    key.split(delimiter)[index]
  end

  protected




  def get_nearby_items(object_id, opts={}) #combined_field, field_value, before, after, page
    items=[]
    original_document = get_solr_response_for_doc_id(object_id)
    combined_key = get_combined_key(original_document[combined_key_field], options[:field_value])

    if !combined_key.nil?
      my_shelfkey = get_shelfkey(combined_key)
      my_reverse_shelfkey = get_reverse_shelfkey(combined_key)

      if page.nil? or page.to_i == 0
        # get preceding bookspines
        items << get_next_spines_from_field(my_reverse_shelfkey, reverse_shelfkey, before, nil)          
        # TODO: can we avoid this extra call to Solr but keep the code this clean?
        # What is the purpose of this call?  To just return the original document?
        items << get_spines_from_field_values([my_shelfkey], shelfkey).uniq
        # get following bookspines
        items << get_next_spines_from_field(my_shelfkey, shelfkey, after, nil)
      else
        if page.to_i < 0 # page is negative so we need to get the preceding docs
          items << get_next_spines_from_field(my_reverse_shelfkey, reverse_shelfkey, (before.to_i+1)*2, page.to_i)
        elsif page.to_i > 0 # page is possitive, so we need to get the following bookspines
          items << get_next_spines_from_field(my_shelfkey, shelfkey, after.to_i*2, page.to_i)
        end
      end
      items.flatten
    end
  end  # get_nearby_items



  # given a shelfkey or reverse shelfkey (for a lopped call number), get the 
  #  text for the next "n" nearby items
  def get_next_spines_from_field(starting_value, field_name, how_many, page)
    number_of_items = how_many
    unless page.nil?
      if page < 0
        page = page.to_s[1,page.to_s.length]
      end
      number_of_items = how_many.to_i * page.to_i+1
    end
    desired_values = get_next_terms_for_field(starting_value, field_name, number_of_items)
    unless page.nil? or page.to_i == 0
      desired_values = desired_values.values_at((desired_values.length-how_many.to_i)..desired_values.length)
    end
    get_spines_from_field_values(desired_values, field_name)
  end
  # return an array of the next terms in the index for the indicated field and 
  # starting term. Returned array does NOT include starting term.  Queries Solr (duh).
  def get_next_terms_for_field(starting_term, field_name, how_many=3)
    result = []
    # terms is array of one element hashes with key=term and value=count
    terms_array = get_next_terms(starting_term, field_name, how_many.to_i+1)
    terms_array.each { |term_hash|
      result << term_hash.keys[0] unless term_hash.keys[0] == starting_term
    }
    result
  end

  # create an array of sorted html list items containing the appropriate display text
  #  (analogous to what would be visible if you were looking at the spine of 
  #  a book on a shelf) from relevant solr docs, given a particular solr
  #  field and value for which to retrieve spine info.
  # Each html list item must match a desired value
  def get_spines_from_field_values(desired_values, field)
    spines_hash = {}
      docs = get_docs_for_field_values(desired_values, field)
      docs.each do |doc|
        hsh = get_spine_hash_from_doc(doc, desired_values, field)
        spines_hash.merge!(hsh) 
      end
      result = []
      spines_hash.keys.sort.each { |sortkey|  
        result << spines_hash[sortkey]
      }
      result
  end

  # create a hash with  
  #     key = sorting key for the spine, 
  #     value = the html list item containing appropriate display text
  #  (analogous to what would be visible if you were looking at the spine of 
  #  a book on a shelf) from a solr doc.  
  #   spine is:  <li> title [(pub year)] [<br/> author] <br/> callnum </li>
  # Each element of the hash must match a desired value in the
  #   desired_values array for the indicated piece (shelfkey or reverse shelfkey)  
  def get_spine_hash_from_doc(doc, desired_values, field)
    result_hash = {}
    return if doc[:item_display].nil?
    # This winnows down the holdings hashs on only ones where the desired values includes the shelfkey or reverse shelfkey using a very quick select statment
    # The resulting array looke like [[:"36105123456789",{:barcode=>"36105123456789",:callnumber=>"PS3156 .A53"}]]
    item_array = doc.holdings_from_solr.select{|k,v| ( (field == shelfkey and desired_values.include?(v[shelfkey.to_sym]) ) or ( field == reverse_shelfkey and desired_values.include?(v[reverse_shelfkey.to_sym]) ) ) }
    temp_holdings_hash = {}
    unless item_array.empty?
      # putting items back into a hash for readibility
      item_array.each do |value|
        temp_holdings_hash[value.first] = value.last
      end
      # looping through the resulting temp hash of holdings to build proper sort keys and then return a hash that conains a solr document for every item in the hash
      temp_holdings_hash.each do |key,value|
        # create sorting key for spine
        # shelfkey asc, then by sorting title asc, then by pub date desc
        # notice that shelfkey and sort_title need to be a constant length
        #  separator of " -|- " is for human readability only
        sort_key = "#{value[shelfkey.to_sym][0,100].ljust(100)} -|- "
        sort_key << "#{doc[:title_sort][0,100].ljust(100)} -|- " unless doc[:title_sort].nil?

        # pub_year must be inverted for descending sort
        if doc[:pub_date].nil? || doc[:pub_date].length == 0
          sort_key << '9999'
        else
         sort_key << doc[:pub_date].tr('0123456789', '9876543210')
        end
        # Adding ckey to sort to make sure we collapse things that have the same callnumber, title, pub date, AND ckey
        sort_key << " -|- #{doc[:id][0,20].ljust(20)}"
        # We were adding the library to the sortkey. However; if we don't add the library we can easily collapse items that have the same
        # call number (shelfkey), title, pub date, and ckey but are housed in different libraries.
        #sort_key << " -|- #{value[:library][0,40].ljust(40)}"

        result_hash[sort_key] = {:doc=>doc,:holding=>value}
      end  # end each item display    
    end
    return result_hash
  end

  # given a document and the barcode of an item in the document, return the
  #  item_display field corresponding to the barcode, or nil if there is no
  #  such item
  def get_combined_key(combined_field, key)
    combined_field.each do |field|
      return field if field.split("-|-").map{|f| f.strip }.include?(key)
    end
  end


  # return the shelfkey (lopped) piece of the item_display field
  def get_shelfkey(combined_key)
    get_combined_key_piece(combined_key, 6)
  end

  # return the reverse shelfkey (lopped) piece of the item_display field
  def get_reverse_shelfkey(combined_key)
    get_combined_key_piece(combined_key, 7)
  end

  def get_combined_key_piece(combined_key, index)
    if combined_key
      item_array = combined_key.split('-|-')
      return item_array[index].strip unless item_array[index].nil?
    end
    nil
  end

  # given a field name and a field value, get the next "alphabetic" N 
  #  terms for the field 
  #  returns array of one element hashes with key=term and value=count
  # NOTE:  terms in index are case sensitive!  Okay for shelfkey ...
  def get_next_terms(curr_value, field, how_many)
    # TermsComponent Query to get the terms
    solr_params = {
      'terms.fl' => field,
      'terms.lower' => curr_value,
      'terms.sort' => 'index',
      'terms.limit' => how_many
    }
    #solr_response = Blacklight.solr.send_request('/alphaTerms', solr_params)
    # Don't like that I have to put /solr/alphaTerms in but RSolr-1.0.0 was constructing the url as :8983/alphaTerms otherwise.
    solr_response = Blacklight.solr.send_and_receive('/solr/alphaTerms', {:params=>solr_params})
    # create array of one element hashes with key=term and value=count
    result = []
    terms ||= solr_response['terms'] || []
    if terms.is_a?(Array)
      field_terms ||= terms[1] || []  # solr 1.4 returns array
    else
      field_terms ||= terms[field] || []  # solr 3.5 returns hash
    end
    # field_terms is an array of value, then num hits, then next value, then hits ...
    i = 0
    until result.length == how_many || i >= field_terms.length do
      term_hash = {field_terms[i] => field_terms[i+1]}
      result << term_hash
      i = i + 2
    end

    result
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