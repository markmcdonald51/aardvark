module Aardvark
  
  
  
  class Runner
    def initialize(sparql_client)
      @sparql_client = sparql_client
    end
    
    def run(query_string)
      @sparql_client.query(query_string).output
    end
  end
end