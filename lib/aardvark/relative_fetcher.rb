module Aardvark
  class RelativeFetcher
    MAPPINGS = {
      father: "P22",
      mother: "P25",
      child: "P40",
      spouse: "P26"
    }
    
    def initialize(sparql_client)
      @client = sparql_client
    end
    
    def fetch(resource, relation)
      relation = MAPPINGS[relation]
      template = File.read("#{Aardvark.root}/query_templates/relative.sparql.erb")
      query_string = ERB.new(template).result(binding)
      solutions = @client.query(query_string)
      solutions.each_solution.map { |v| v.each_value.map(&:to_s) }.group_by {|x| x[0] }.values.map{|v| v.find {|v| v[1].match(/en.wiki/) }}.compact.map {|x| x[2] = gender(x[2]); x}
    end
    
    private
    def gender(entity)
      if entity == "http://www.wikidata.org/entity/Q6581072"
        "F"
      else
        "M"
      end
    end
  end
end