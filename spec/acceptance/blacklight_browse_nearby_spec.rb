require "spec_helper"
describe "BlacklightBrowseNearby" do
  before(:each) do
    @document_response  = {"hits" => "1"}
    @original_document  = {"id" => "666", "value_display" => ["FFFF", "NNNN"], "shelfkey" => ["ffff", "nnnn"], "reverse_shelfkey" => ["zzzz", "mmmm"], "combined_shelfkey" => ["FFFF -|- ffff -|- uuuu", "NNNN -|- nnnn -|- mmmm"]}
    @previous_terms     = {"terms" => {"reverse_shelfkey" => ["yyyy", 1, "xxxx", 1, "wwww", 1, "vvvv", 1, "uuuu", 1]}}
    @next_terms         = {"terms" => {"shelfkey"         => ["gggg", 1, "hhhh", 1, "iiii", 1, "jjjj", 1, "kkkk", 1]}}  
    @previous_documents = [{"id"=>"222",  "value_display" => "BBBB"},
                           {"id"=>"333",  "value_display" => "CCCC"},
                           {"id"=>"444",  "value_display" => "DDDD"},
                           {"id"=>"555",  "value_display" => "EEEE"}]
    @next_documents     = [{"id"=>"777",  "value_display" => "GGGG"},
                           {"id"=>"888",  "value_display" => "HHHH"},
                           {"id"=>"999",  "value_display" => "IIII"},
                           {"id"=>"1010", "value_display" => "JJJJ"}]
  end
  it "should combine the previous, current, and next documents returned from solr" do
    Blacklight.stub(:solr).and_return(mock("solr"))
    Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
    Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
    docs = BlacklightBrowseNearby.new("123").documents
    docs.should be_a(Array)
    docs.length.should == 9
    docs.map{|d| d["value_display"] }.should == [@previous_documents,@original_document,@next_documents].flatten.map{|d| d["value_display"]}
    docs.map{|d| d["value_display"] }.should == ["BBBB", "CCCC", "DDDD", "EEEE", ["FFFF", "NNNN"], "GGGG", "HHHH", "IIII", "JJJJ"]
  end
  
  it "should return an embty array if the object does not have all the required fields" do
    Blacklight.stub(:solr).and_return(mock("solr"))
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response, {"id"=>"someid", "title_display" => "MyDocument"}])
    BlacklightBrowseNearby.new("123").documents.should be_blank
  end

  describe "originating document" do
    it "should have the original document available" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      nearby.original_document.should == @original_document
    end
    describe "current_value" do
      it "should return the current value of the originating document" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.current_value.should == @original_document["value_display"].first
      end
      it "should return the preferred value if one is provided " do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"nnnn", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"mmmm", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123", :preferred_value=>"NNNN")
        nearby.current_value.should == @original_document["value_display"].last
      end
    end
    describe "potential_values" do
      it "should return all the value fields from the current document" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.potential_values.should == @original_document["value_display"]
      end
    end
  end

  describe "Options" do  
    describe "start_of_terms" do
      it "should start at the beginning of the terms when there is no page" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.start_of_terms.should == 0
      end
      it "should start at the last set of terms based on the number requested" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 7}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["iiii", "jjjj", "kkkk"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "1", :number => 5)
        nearby.start_of_terms.should == 2
      end
    end
    
    describe "total_terms" do
      it "should return half of the number requested when on the inital query" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 3}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>3}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx", "wwww"], {:per_page=>3}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh", "iiii"], {:per_page=>3}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123", :number => 7)
        nearby.total_terms.should == 3
      end
      it "should return the correct number of of terms when paging" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 4}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["hhhh", "iiii", "jjjj"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "1", :number => "3")
        nearby.total_terms.should == 4
      end
    end
    
    describe "hits_requested" do
      it "should return the configured default when no page option is provided" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.hits_requested.should == 5
      end
      it "should return the number option is one if provided" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 3}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>3}}).and_return(@previous_terms)
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
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.original_query_offset.should == 2
      end
      it "should return half the requested items in the presence of a number" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 3}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>3}}).and_return(@previous_terms)
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
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
        nearby = BlacklightBrowseNearby.new("123")
        nearby.normalized_page.should == 0
      end
      it "should return a positive integer when a negative page is requested" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>7}}).and_return(@previous_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["wwww", "vvvv", "uuuu"], {:per_page=>3}).and_return([@document_response, @previous_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "-1")
        nearby.normalized_page.should == 1
      end
    end
      
    describe "Number option" do
      it "should return the correct documents when pages are added" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
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
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 7}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["iiii", "jjjj", "kkkk"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :page => "1")
        nearby.total_terms.should == 7
        nearby.start_of_terms.should == 2
      end
      it "should properly paginate the total and start hit counts" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 7}}).and_return(@next_terms)
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
        BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["iiii", "jjjj", "kkkk"], {:per_page=>3}).and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
        nearby = BlacklightBrowseNearby.new("123", :number => "5", :page => "1")
        nearby.total_terms.should == 7
        nearby.start_of_terms.should == 2
      end
      it "should properly handle negative page numbers" do
        Blacklight.stub(:solr).and_return(mock("solr"))
        Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>7}}).and_return(@previous_terms)
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
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      combined_key = "value_displayMATCH -|- shelfkeyMATCH -|- reverse_shelfkeyMATCH"
      ["shelfkey", "value_display", "reverse_shelfkey"].each do |part|
        nearby.send(:get_value_from_combined_key, combined_key, part).should == "#{part}MATCH"
      end
    end
    it "should return the first key when a preferred value is not requested" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      nearby.combined_key.should == "FFFF -|- ffff -|- uuuu"
    end
    it "should return the first key when there is only one available" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"nnnn", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"mmmm", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document.merge("combined_shelfkey"=>[@original_document["combined_shelfkey"].last])])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      nearby.combined_key.should == "NNNN -|- nnnn -|- mmmm"
    end
    it "should return the key matching the preferred value if one is given" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"shelfkey", :"terms.lower"=>"nnnn", :"terms.limit" => 2}}).and_return(@next_terms)
      Blacklight.solr.should_receive(:send_and_receive).with("alphaTerms", {:params => {:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"mmmm", :"terms.limit"=>2}}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("reverse_shelfkey", ["yyyy", "xxxx"], {:per_page=>2}).and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with("shelfkey", ["gggg", "hhhh"], {:per_page=>2}).and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123", :preferred_value=>"NNNN")
      nearby.combined_key.should == "NNNN -|- nnnn -|- mmmm"
    end
  end
end