require 'erb'
require 'rubygems'
require 'crack'
require 'json'
require 'pry'
#Preparing hash with list node and their children
#EX : {"1234": { children: [{id: "2323",name: "child1"}], name: "parent" } }
def build_children_hierarchy(taxonomy_hierarchy,parent,node)
  
  taxonomy_hierarchy[parent] = taxonomy_hierarchy[parent] || {children: [],name: ""}

  if node["node"].class == Array
    taxonomy_hierarchy[parent][:children] = node["node"].map{|n| {id: n["atlas_node_id"], name: n["node_name"] } }
    taxonomy_hierarchy[parent][:name] = node["node_name"]

    node["node"].each do |n|
      build_children_hierarchy(taxonomy_hierarchy,n["atlas_node_id"],n)
    end
  elsif node["node"].class == Hash
    taxonomy_hierarchy[parent][:children] << {id: node["node"]["atlas_node_id"], name: node["node"]["node_name"] }
    taxonomy_hierarchy[parent][:name] = node["node_name"]

    build_children_hierarchy(taxonomy_hierarchy,node["atlas_node_id"],node["node"])
  else    
    taxonomy_hierarchy[node["atlas_node_id"]] = {children: [],name: node["node_name"]}
  end

end

#Return parent node information in hash object
def get_parent(taxonomy_hierarchy,id)
  taxonomy_hierarchy.each do |k|        
    k[1][:children].each do |v|
      return {id: k[0],name: k[1][:name]} if v[:id] == id
    end
  end
  nil
end

#Check if result folder is exists and create if it doesn't exists
def find_or_create_destination_folder
  Dir.mkdir(HTML_RESULT_FOLDER) if !Dir.exists?HTML_RESULT_FOLDER
end

#Main code of execution
begin

  HTML_RESULT_FOLDER = 'generated_html'
  TAXANOMY_FILE_PATH = './taxonomy.xml'
  DESTINATION_FILE_PATH = './destinations.xml'
  ERB_TEMPLATE_PATH = './template.html.erb'

  #Converting XML to JSON for easy manupulation
  taxonomy_xml  = Crack::XML.parse(File.read(TAXANOMY_FILE_PATH))
  taxonomy_json = JSON.parse(taxonomy_xml.to_json)

  destinations_xml  = Crack::XML.parse(File.read(DESTINATION_FILE_PATH))
  destinations_json = JSON.parse(destinations_xml.to_json)

  #Hash object to hold taxonomy child and parent relation
  taxonomy_hierarchy = {}

  root_taxonomies = taxonomy_json["taxonomies"]["taxonomy"]
  build_children_hierarchy(taxonomy_hierarchy,root_taxonomies["node"]["atlas_node_id"],root_taxonomies["node"])

  #Getting all destination nodes
  destinations_array =  destinations_json["destinations"]["destination"]

  find_or_create_destination_folder

  #Iteraging through all destination and generating HTML for them
  destinations_array.each do |destination|

    #Starting garbadge collection
    GC.stat
    
    tmp_hash = {}
    tmp_hash[:title] = destination["title"] rescue "No title"

    #can add more information we can. But for now I am adding history only
    tmp_hash[:history] = destination["history"]["history"]["history"] rescue []
    tmp_hash[:atlas_id] = destination["atlas_id"] rescue 0
    tmp_hash[:children] = taxonomy_hierarchy[tmp_hash[:atlas_id]][:children]  
    tmp_hash[:parent] = get_parent(taxonomy_hierarchy,tmp_hash[:atlas_id])

    #Generating HTML
    erb_str = File.read(ERB_TEMPLATE_PATH)
    renderer = ERB.new(erb_str)
    b = binding
    b.local_variable_set(:destination, tmp_hash)

    result = renderer.result(b)

    html_file = "#{HTML_RESULT_FOLDER}/#{tmp_hash[:atlas_id]}.html"
    File.open(html_file, 'w') do |f|
      f.write(result)
    end

  end

rescue Exception => e
  #We can handle specific exception to perform action.
  #As this is test project, I just catch Base Exception.
  puts "Exception occured => #{e.message}"
end