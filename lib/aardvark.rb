require "active_record"
require "ancestry"
require 'sparql/client'
require 'rdf/raptor'
require 'erb'
require 'yaml'
require 'ostruct'

require "aardvark/version"
require "aardvark/sampler"
config = YAML.load_file("./lib/aardvark/config/database.yml")
ActiveRecord::Base.establish_connection(config)
require "aardvark/models/reptiloid"
require "aardvark/models/shapeshifter"
require "aardvark/reptiloid_finder"
require "aardvark/reptiloid_child_finder"
require "aardvark/relative_fetcher"
require "aardvark/dbpedia_relative_fetcher"
require 'aardvark/crawlers/family_web_builder'
require 'aardvark/crawlers/dbp_family_web_builder'

require 'aardvark/crawlers/details_adder'

require 'aardvark/linker/linker'
require 'aardvark/linker/tree_builder'


module Aardvark
  extend self
  
  def r
    Shapeshifter
  end
  
  def c
    SPARQL::Client.new("http://localhost:3030/wikidata/sparql")
  end
  
  def dbp_client
    SPARQL::Client.new("http://localhost:3031/dbpedia/sparql")
  end
  
  def root
    `pwd`.chomp + "/lib/aardvark"
  end
  
  def linker
    Linker::ChainFinder.new(Shapeshifter)
  end
  
  def run_linker
    #Q720 = Genghis Khan
    #Q9682 = Queen
    #Q9439 = Queen Victoria
    #Q8016 = Churchill
    #Q130805 = George I  
    #Q37594 = William the Conqueror
    #Q565438 Arnoald
    #Q2685 Schwarzenegger
    #Q273773 Rollo
    #Q191103 Lucrezia Borgia
    #Q152316 Prince Harry
    #Q232465 Pippa Middleton
    #Q517 Napoloen
    #Q58165 Merovech
    #Q243453 Charibert I
    #Q102371 Alaric I
    @last_report = linker.find(Shapeshifter.find_by(resource: "Q243453"), Shapeshifter.find_by(resource: "Q102371"))
    tree_builder.build(@last_report.shortest_chains.first)
  end
  
  def tree_builder
    Aardvark::Linker::TreeBuilder
  end
  
  def finder
    ReptiloidFinder.new(c)
  end
  
  def child_finder
    ReptiloidChildFinder.new(c)
  end
  
  def details_adder
    Crawlers::DetailsAdder.new(dbp_client, Shapeshifter)
  end
  
  def family_web_builder
    relative_fetcher = RelativeFetcher.new(c)    
    Crawlers::FamilyWebBuilder.new(relative_fetcher)
  end
  
  def dbp_family_web_builder
    relative_fetcher = DbpediaRelativeFetcher.new(dbp_client)    
    Crawlers::DbpFamilyWebBuilder.new(relative_fetcher)
  end
  
  alias_method :f, :family_web_builder
  
end
