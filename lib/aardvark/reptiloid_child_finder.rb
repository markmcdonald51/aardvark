module Aardvark
  class ReptiloidChildFinder < ReptiloidFinder
    def run(root)
      @count =0
      build_root(root) unless repo.find_by(resource: root)
      while candidates.any? do
        candidates.each do |c|
          children = get_children(c)
          if children.empty?
            c.update_column(:dead_end, true)
          else
            c.update_column(:done, true)
            children.each do |p|
              v = c.parents_found
              c.update_column(:parents_found, v+1)
              build_person(p, c)
            end
          end
        end
      end
    end


    def get_children(person)
      # P22 = father
      
      resource = person.resource
      relation = "P40"
      query_string = ERB.new(template("relative")).result(binding)
      solutions = @client.query(query_string)
      # if solutions.empty?
      #   query_string = ERB.new(template("mini_parent")).result(binding)
      #   
      #   solutions = @client.query(query_string)
      solutions.each_solution.map { |v| v.each_value.map(&:to_s) }.map{|s| s[1] ||= "en.wikipedia.org:NOT FOUND"; s }.select {|s| s[1].match(/en.wikiped/) }
    end
  end
end