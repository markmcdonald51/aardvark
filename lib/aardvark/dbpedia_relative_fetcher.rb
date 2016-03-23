module Aardvark
  module DbpediaFetchers
    class Base
      def initialize(sparql_client, person)
        @client = sparql_client
        @person = person
      end

      def raw_solutions
        relationship_predicates.map do |relationship|
          query_string = ERB.new(template).result(binding)
          @client.query(query_string)
        end.find {|y| y.any? }
      end
      
      def template
        File.read("#{Aardvark.root}/query_templates/dbpedia/relative.sparql.erb")
      end
      
      def solutions
        raw_solutions.each_solution.map { |v| v.each_value.map(&:to_s) }.group_by {|x| x[0] }.values.map {|x| x.first } rescue []
      end
    end
    
    class FatherFetcher < Base
      def relationship_predicates
        ["dbp:father", "dbo:parent"]
      end
      
      # def solutions
      #   if super.any?
      #     super.first.tap {|x| x << "M"}
      #   else 
      #     []
      #   end
      # end
    end
    
    class MotherFetcher < Base
      def relationship_predicates
        ["dbp:mother", "dbo:parent"]
      end
      
      # def solutions
      #   if super.any?
      #     super.first.tap {|x| x << "F"}
      #   else 
      #     []
      #   end
      # end
    end
    
    class ChildFetcher < Base
      def relationship_predicates
        ["_"]
      end
      
      def template
        File.read("#{Aardvark.root}/query_templates/dbpedia/children.sparql.erb")
      end
    end
    
    class SpouseFetcher < Base
      def relationship_predicates
        ["dbo:spouse"]
      end
    end
  end
  
  class DbpediaRelativeFetcher 

    
    def initialize(sparql_client)
      @client = sparql_client
    end
    
    def fetch(resource, relation)
      klass = Aardvark::DbpediaFetchers.const_get(relation.to_s.capitalize+"Fetcher")
      
      klass.new(@client, resource).solutions
    end
  end
end