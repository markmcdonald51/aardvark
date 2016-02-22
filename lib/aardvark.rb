require "aardvark/version"
require "aardvark/sampler"
require 'sparql/client'
require 'rdf/raptor'
require 'erb'
require 'yaml'

module Aardvark
  def self.root
    `pwd`.chomp + "/lib/aardvark"
  end
  
  def self.run(query_name, options={})
    template = File.read("#{root}/query_templates/#{query_name}.sparql.erb")
    query_string = ERB.new(template).result(binding)
    config = YAML.load_file("#{root}/config/config.yml")[query_name.to_s]
    client = SPARQL::Client.new(config["endpoint"])
    solutions = client.query(query_string)
    solutions.each_solution.map { |v| v.each_value.map(&:to_s) }     
  end
  
  def self.ancestry(resource, generations=10)
    people = {}
    generations.times.inject([resource]) do |memo, _|
      puts "memo: #{memo}"
      memo.flatten.map do |person|
        # puts "person: #{person}"
        parents = run(:parents, resource: person).flatten
        puts "parents: #{parents}"
        people[person] = parents
        parents
      end
    end
    people
  end
end
