require_relative 'processor'
require 'test/unit'
require 'pry'

class TestProcessor < Test::Unit::TestCase
 
  def test_constants
    assert_equal('generated_html', Processor::HTML_RESULT_FOLDER)
    assert_equal('./taxonomy.xml', Processor::TAXANOMY_FILE_PATH)
    assert_equal('./destinations.xml', Processor::DESTINATION_FILE_PATH)
    assert_equal('./template.html.erb', Processor::ERB_TEMPLATE_PATH)
  end
 
  def test_convert_xml_to_json
    processor = Processor.new
    taxonomy_json = processor.convert_xml_to_json(Processor::TAXANOMY_FILE_PATH)
    destinations_json = processor.convert_xml_to_json(Processor::DESTINATION_FILE_PATH)
    assert_equal(Hash,taxonomy_json.class)
  end

  def test_build_children_hierarchy
    processor = Processor.new
    taxonomy_json = processor.convert_xml_to_json(Processor::TAXANOMY_FILE_PATH)
    destinations_json = processor.convert_xml_to_json(Processor::DESTINATION_FILE_PATH)

    #Hash object to hold taxonomy child and parent relation
    taxonomy_hierarchy = {}

    root_taxonomies = taxonomy_json["taxonomies"]["taxonomy"]
    processor.build_children_hierarchy(taxonomy_hierarchy,root_taxonomies["node"]["atlas_node_id"],root_taxonomies["node"])    
    assert_equal(true,taxonomy_hierarchy["355064"].has_key?(:children),"Invalid hash")
    assert_equal(true,taxonomy_hierarchy["355064"].has_key?(:children),"Invalid hash")
    assert_equal(Array,taxonomy_hierarchy["355064"][:children].class,"Invalid children")
    assert_equal(true,taxonomy_hierarchy["355064"][:children][0].has_key?(:id),"Invalid children element key")
    assert_equal(true,taxonomy_hierarchy["355064"][:children][0].has_key?(:name),"Invalid children element key")
    assert_equal("Africa",taxonomy_hierarchy["355064"][:name],"Invalid name")

  end

  def test_get_parent
    processor = Processor.new
    taxonomy_json = processor.convert_xml_to_json(Processor::TAXANOMY_FILE_PATH)
    destinations_json = processor.convert_xml_to_json(Processor::DESTINATION_FILE_PATH)

    #Hash object to hold taxonomy child and parent relation
    taxonomy_hierarchy = {}

    root_taxonomies = taxonomy_json["taxonomies"]["taxonomy"]
    processor.build_children_hierarchy(taxonomy_hierarchy,root_taxonomies["node"]["atlas_node_id"],root_taxonomies["node"])
    
    res = processor.get_parent(taxonomy_hierarchy,"355612")
    assert_equal(Hash, res.class,"Invalid parent result")
    assert_equal(true, res.has_key?(:id),"Invalid hash key")
    assert_equal(true, res.has_key?(:name),"Invalid hash key")
    assert_equal("355611", res[:id],"Invalid result key")
    assert_equal("South Africa", res[:name],"Invalid result name")

  end

  def test_find_or_create_destination_folder
    processor = Processor.new
    processor.find_or_create_destination_folder
    assert_equal(true,Dir.exists?(Processor::HTML_RESULT_FOLDER))
  end

  def test_execute
    processor = Processor.new
    destinations_json = processor.convert_xml_to_json(Processor::DESTINATION_FILE_PATH)
    destinations_array =  destinations_json["destinations"]["destination"]
    processor.execute
    assert_equal(true,Dir.exists?(Processor::HTML_RESULT_FOLDER))    
    destinations_array.each do |d|
      assert_equal(true,File.exists?("#{Processor::HTML_RESULT_FOLDER}/#{d['atlas_id']}.html"))
    end
  end
end