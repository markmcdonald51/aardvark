module Aardvark
  class ReptiloidFinder
    def initialize(client)
      @client = client
    end
    
    def run(root)
      @count =0
      build_root(root) unless repo.find_by(resource: root)
      while candidates.any? do
        candidates.each do |c|
          parents = get_parents(c)
          if parents.empty?
            c.update_column(:dead_end, true)
          else
            c.update_column(:done, true)
            parents.each do |p|
              v = c.parents_found
              c.update_column(:parents_found, v+1)
              build_person(p, c)
            end
          end
        end
      end
    end

    def get_parents(person)
      [get_parent(person, "P25"), get_parent(person, "P22")]
    end
    
    def get_parent(person, type)
      # P22 = father
      
      resource = person.resource
      relation = type
      query_string = ERB.new(template("relative")).result(binding)
      solutions = @client.query(query_string)
      # if solutions.empty?
      #   query_string = ERB.new(template("mini_parent")).result(binding)
      #   
      #   solutions = @client.query(query_string)
      solutions.each_solution.map { |v| v.each_value.map(&:to_s) }.map{|s| s[1] ||= "en.wikipedia.org:NOT FOUND"; s }.find {|s| s[1].match(/en.wikiped/) }
    end
    
    def repo
      Aardvark::Reptiloid
    end
    
    def candidates
      repo.where("done is null and dead_end is null")
    end
    
    def build_root(root)
      repo.create(
        resource: root
      )
    end
    
    def build_person(attributes, child)
      return true if attributes.nil?
      resource = attributes[0].split("/").last
      unless repo.find_by(resource: resource)
        @count += 1
        puts "#{@count} => #{attributes[1]} == #{attributes[2]}"
        person = repo.create(
          resource: resource, 
          name: attributes[1], 
          birth_date: attributes[2],
          birth_place: attributes[3],
          parent: child #doing a kind of "reverse" ancestry where the queen is the head of the hierarchy
        )
      else
        true
      end
    end
    
    def template(name)
      File.read("#{Aardvark.root}/query_templates/#{name}.sparql.erb")
    end
    
  end
end