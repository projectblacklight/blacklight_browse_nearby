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
    Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.sort"=>"index", :"terms.limit" => 4, :qt => "alpha_terms"}).and_return(@next_terms)
    Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.sort"=>"index", :"terms.limit"=>4, :qt=>"alpha_terms"}).and_return(@previous_terms)
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["yyyy", "xxxx", "wwww", "vvvv"], "reverse_shelfkey").and_return([@document_response, @previous_documents])
    BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["gggg", "hhhh", "iiii", "jjjj"], "shelfkey").and_return([@document_response, @next_documents])
    docs = BlacklightBrowseNearby.new("123").documents
    docs.length.should == 9
    docs.map{|d| d["callnumber"] }.should == [@previous_documents,@original_document,@next_documents].flatten.map{|d| d["callnumber"]}
    docs.map{|d| d["callnumber"] }.should == ["BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ"]
  end

  describe "Number option" do
    it "should return the correct documents when pages are added" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.sort"=>"index", :"terms.limit"=>2, :qt=>"alpha_terms"}).and_return(@previous_terms)
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.sort"=>"index", :"terms.limit" => 2, :qt => "alpha_terms"}).and_return(@next_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["gggg", "hhhh"], "shelfkey").and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["yyyy", "xxxx"], "reverse_shelfkey").and_return([@document_response, @previous_documents]) # this isn't the right set of documents, but that's not what we're testing.
      nearby = BlacklightBrowseNearby.new("123", :number => "2")
      nearby.total_hits.should == 2
      nearby.start_of_hits.should == 0
    end
  end
  describe "Page option" do
    it "should properly paginate the total and start hit counts" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.sort"=>"index", :"terms.limit"=>4, :qt=>"alpha_terms"}).and_return(@previous_terms)
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.sort"=>"index", :"terms.limit" => 4, :qt => "alpha_terms"}).and_return(@next_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["iiii", "jjjj"], "shelfkey").and_return([@document_response, @next_documents]) # this isn't the right set of documents, but that's not what we're testing.
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["wwww", "vvvv"], "reverse_shelfkey").and_return([@document_response, @previous_documents]) # this isn't the right set of documents, but that's not what we're testing.
      nearby = BlacklightBrowseNearby.new("123", :number => "2", :page => "1")
      nearby.total_hits.should == 4
      nearby.start_of_hits.should == 2
    end
  end
  describe "combined key" do      
    it "should correctly parse from the pattern" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.sort"=>"index", :"terms.limit" => 4, :qt => "alpha_terms"}).and_return(@next_terms)
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.sort"=>"index", :"terms.limit"=>4, :qt=>"alpha_terms"}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["yyyy", "xxxx", "wwww", "vvvv"], "reverse_shelfkey").and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["gggg", "hhhh", "iiii", "jjjj"], "shelfkey").and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      combined_key = "callnumberMATCH -|- shelfkeyMATCH -|- reverse_shelfkeyMATCH"
      ["shelfkey", "callnumber", "reverse_shelfkey"].each do |part|
        nearby.send(:get_value_from_combined_key, combined_key, part).should == "#{part}MATCH"
      end
    end
    it "should return the only key when only one is available" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:find).twice.with({:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.sort"=>"index", :"terms.limit" => 4, :qt => "alpha_terms"}).and_return(@next_terms)
      Blacklight.solr.should_receive(:find).twice.with({:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.sort"=>"index", :"terms.limit"=>4, :qt=>"alpha_terms"}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["yyyy", "xxxx", "wwww", "vvvv"], "reverse_shelfkey").and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["gggg", "hhhh", "iiii", "jjjj"], "shelfkey").and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz"]).should == "AAAA -|- aaaa -|- zzzz"
      nearby = BlacklightBrowseNearby.new("123", :preferred_value=>"something")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz"]).should == "AAAA -|- aaaa -|- zzzz"
    end
    it "should return the first key when multiple are available" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.sort"=>"index", :"terms.limit" => 4, :qt => "alpha_terms"}).and_return(@next_terms)
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.sort"=>"index", :"terms.limit"=>4, :qt=>"alpha_terms"}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["yyyy", "xxxx", "wwww", "vvvv"], "reverse_shelfkey").and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["gggg", "hhhh", "iiii", "jjjj"], "shelfkey").and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz", "BBBB -|- bbbb -|- yyyy"]).should == "AAAA -|- aaaa -|- zzzz"
    end
    it "should return the key matching a preferred value if one is supplied (e.g. multi-valued fields)" do
      Blacklight.stub(:solr).and_return(mock("solr"))
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"shelfkey", :"terms.lower"=>"ffff", :"terms.sort"=>"index", :"terms.limit" => 4, :qt => "alpha_terms"}).and_return(@next_terms)
      Blacklight.solr.should_receive(:find).with({:"terms.fl"=>"reverse_shelfkey", :"terms.lower"=>"uuuu", :"terms.sort"=>"index", :"terms.limit"=>4, :qt=>"alpha_terms"}).and_return(@previous_terms)
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_doc_id).and_return([@document_response,@original_document])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["yyyy", "xxxx", "wwww", "vvvv"], "reverse_shelfkey").and_return([@document_response, @previous_documents])
      BlacklightBrowseNearby.any_instance.stub(:get_solr_response_for_field_values).with(["gggg", "hhhh", "iiii", "jjjj"], "shelfkey").and_return([@document_response, @next_documents])
      nearby = BlacklightBrowseNearby.new("123", :preferred_value => "BBBB")
      nearby.send(:get_combined_key, ["AAAA -|- aaaa -|- zzzz", "BBBB -|- bbbb -|- yyyy"]).should == "BBBB -|- bbbb -|- yyyy"
    end
  end
end

# ops =     {
#   :"terms.fl"    => "shelfkey",
#   :"terms.lower" => "aaaaabbbbbcccccddddd",
#   :"terms.sort"  => "index",
#   :"terms.limit" => 5
# }