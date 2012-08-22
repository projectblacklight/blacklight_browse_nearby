require "spec_helper"
describe "BlacklightBrowseNearby" do
  before(:each) do
    @document_response  = {"hits" => "1"}
    @original_document  = {"id" => "666", "callnumber" => "FFFF", "shelfkey" => "ffff", "reverse_shelfkey" => "zzzz", "combined_shelfkey" => ["FFFF -|- ffff -|- uuuu"]}
    @previous_terms     = {"terms" => {"reverse_shelfkey" => ["yyyy", 1, "xxxx", 1, "wwww", 1, "vvvv", 1, "uuuu", 1]}}
    @next_terms         = {"terms" => {"shelfkey"         => ["gggg", 1, "hhhh", 1, "iiii", 1, "jjjj", 1, "kkkk", 1]}}  
    @previous_documents = [{"id"=>"222",  "callnumber" => "BBBB"},
                           {"id"=>"333",  "callnumber" => "CCCC"},
                           {"id"=>"444",  "callnumber" => "DDDD"},
                           {"id"=>"555",  "callnumber" => "EEEE"}]
    @next_documents     = [{"id"=>"777",  "callnumber" => "GGGG"},
                           {"id"=>"888",  "callnumber" => "HHHH"},
                           {"id"=>"999",  "callnumber" => "IIII"},
                           {"id"=>"1010", "callnumber" => "JJJJ"}]
  end
  it "should combine the previous, current, and next documents returned from solr" do
    Blacklight.stub(:solr).and_return(mock("solr"))
    Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
    Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
    docs = BlacklightBrowseNearby.new("123").documents
    docs.should be_a(Array)
    docs.length.should == 9
    docs.map{|d| d["callnumber"] }.should == [@previous_documents,@original_document,@next_documents].flatten.map{|d| d["callnumber"]}
    docs.map{|d| d["callnumber"] }.should == ["BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ"]
  end


  describe "Options" do  
    describe "start_of_terms" do
      it "should start at the beginning of the terms when there is no page" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.start_of_terms.should == 0
      end
      it "should start at the last set of terms based on the number requested" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 7}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["iiii", "jjjj", "kkkk"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "1", :number => 5)
        nearby.start_of_terms.should == 2
      end
    end
    
    describe "total_terms" do
      it "should return half of the number requested when on the inital query" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 3}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>3}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx", "wwww"], {:per_page=>3}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh", "iiii"], {:per_page=>3}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123", :number => 7)
        nearby.total_terms.should == 3
      end
      it "should return the correct number of of terms when paging" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 4}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["hhhh", "iiii", "jjjj"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "1", :number => "3")
        nearby.total_terms.should == 4
      end
    end
    
    describe "hits_requested" do
      it "should return the configured default when no page option is provided" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.hits_requested.should == 5
      end
      it "should return the number option is one if provided" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 3}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>3}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx", "wwww"], {:per_page=>3}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh", "iiii"], {:per_page=>3}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123", :number => 7)
        nearby.hits_requested.should == 7
      end
    end
    
    describe "original_query_offset" do
      it "should return half the configured items in the absence of a requested number" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.original_query_offset.should == 2
      end
      it "should return half the requested items in the presence of a number" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 3}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>3}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx", "wwww"], {:per_page=>3}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh", "iiii"], {:per_page=>3}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123", :number => 7)
        nearby.original_query_offset.should == 3
      end
    end
    
    describe "normalized_page" do
      it "should return 0 when no page option is provided" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.normalized_page.should == 0
      end
      it "should return a positive integer when a negative page is requested" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>7}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["wwww", "vvvv", "uuuu"], {:per_page=>3}).and_return([@document_response, @previous_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "-1")
        nearby.normalized_page.should == 1
      end
    end
      
    describe "Number option" do
      it "should return the correct documents when pages are added" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :number => "5")
        nearby.total_terms.should == 2
        nearby.start_of_terms.should == 0
      end
    end
    describe "Page option" do
      it "should handle simple paging w/ no number provided" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 7}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["iiii", "jjjj", "kkkk"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "1")
        nearby.total_terms.should == 7
        nearby.start_of_terms.should == 2
      end
      it "should properly paginate the total and start hit counts" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 7}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["iiii", "jjjj", "kkkk"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :number => "5", :page => "1")
        nearby.total_terms.should == 7
        nearby.start_of_terms.should == 2
      end
      it "should properly handle negative page numbers" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>7}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["wwww", "vvvv", "uuuu"], {:per_page=>3}).and_return([@document_response, @previous_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :number => "5", :page => "-1")
        nearby.total_terms.should == 7
        nearby.start_of_terms.should == 2
      end
    end
  end
  
  describe "combined key" do      
    it "should correctly parse from the pattern" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      combined_key = "callnumberMATCH -|- shelfkeyMATCH -|- reverse_shelfkeyMATCH"
      ["shelfkey", "callnumber", "reverse_shelfkey"].each do |part|
        nearby.send(:get_value_from_combined_key, combined_key, part).should == "#{part}MATCH"
      end
    end
    it "should return the only key when only one is available" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).twice.with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).twice.with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz"]).should == "AAAA -|- aaaa -|- zzzz"
      nearby = BlacklightBrowseNearby.new("123", :preferred_value=>"something")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz"]).should == "AAAA -|- aaaa -|- zzzz"
    end
    it "should return the first key when multiple are available" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz", "BBBB -|- bbbb -|- yyyy"]).should == "AAAA -|- aaaa -|- zzzz"
    end
    it "should return the key matching a preferred value if one is supplied (e.g. multi-valued fields)" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("/solr/alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123", :preferred_value => "BBBB")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz", "BBBB -|- bbbb -|- yyyy"]).should == "BBBB -|- bbbb -|- yyyy"
    end
  end
end