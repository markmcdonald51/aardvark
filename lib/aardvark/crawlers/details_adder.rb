module Aardvark
  module Crawlers
    class DetailsAdder
      def initialize(sparql_client, repo)
        @client = sparql_client
        @repo = repo
      end
      
      def run
        @repo.where(birth_date: nil).each do |r|
          update(r)
        end
      end
      
      def update(record)
        resource = record.resource
        query_string = ERB.new(template).result(binding)
        solutions = @client.query(query_string)
        solutions = solutions.each_solution.map { |v| v.each_value.map(&:to_s) }.first
        
        solutions[1] = Time.new(Date.parse(solutions[1])) rescue Time.new(Date.parse(solutions[4])) rescue nil
        
        solutions ||= []
        puts "updating #{record.name} ==> #{solutions[1]}, #{solutions[4]} ==> #{solutions[2]}"
        # binding.pry
        
        record.update_attributes!(
          birth_date: solutions[1],
          birth_place: solutions[2],
          birth_place_geo: solutions[3]
        )
      end
      
      private
      def template
        @_template = File.read("#{Aardvark.root}/query_templates/dbpedia/additional_details.sparql.erb")
      end
    end
  end
end