module Aardvark
  module Linker
    class Connection
      def initialize(name, predicate, stack)
        @name = name
        @predicate = predicate
        @stack = stack
      end
      
      def links(node)
        @predicate.call(node).compact.to_a.select do |s| 
          @stack.exclude?(s.resource) 
        end.map do |new_node| 
          Link.new(@name, new_node) if new_node
        end.compact
      end
      
    end
    
    class Chain
      include Enumerable
      attr_reader :links
      
      def each &block
        links.each(&block)
      end
      
      def initialize(links)
        @links = links
        @links
      end
      
      def last_node
        @links.last.node
      end
      
      def flatten
        self
      end
      
      def size
        links.size
      end
    end
    
    # class ChainLink
    #   def initialize(chain, link)
    #     @chain = chain
    #     @link = link
    #   end
    #   
    #   def inspect
    #     "CHAINLINK: #{name}=>#{node.display_name}"
    #   end
    #   
    #   def next
    #     
    #   end
    #   
    #   def method_missing(method_name, *args, &block)
    #     if @link.respond_to?(method_name)
    #       @link.send(method_name, *args, &block)
    #     else
    #       super
    #     end
    #   end
    # 
    #   def respond_to_missing?(method_name, include_private = false)
    #     @link.respond_to?(method_name) || super
    #   end
    # end
    
    class Link
      attr_accessor :name, :node
      def initialize(name, node)
        # puts "initialising link with: #{name} ==> #{node.resource}"
        @name = name
        @node = node
      end
      
      def inspect
        "LINK: #{name}=>#{node.display_name}"
      end
    end
    
    class ChainFinder
      attr_reader :open_chains, :closed_chains, :visited
      CONNECTION_CONFIG = {
        father: ->(node)   { [node.father] },
        mother: ->(node)   { [node.mother] },
        children: ->(node) { node.children },
        spouses: ->(node)  { node.spouses },
        siblings: ->(node)  { node.siblings }
      }
      
      def initialize(repo)
        @repo = repo
        @visited = []
        @open_chains = []
        @closed_chains = []
      end
      
      def find(startpoint, endpoint)
        @endpoint = endpoint
        @open_chains = [Chain.new([Link.new(:start, startpoint)])]
        last_count = nil
        # while (@visited.count < @repo.count || !@visited.map(&:resource).include?(endpoint.resource)) do
        while true do
          return self if last_count == @visited.count #i.e. it hasn't changed
          
          last_count = @visited.count
          # puts "===> COUNT: #{@visited.count}"
          # binding.pry if @visited.count == 17
          # binding.pry
          @open_chains.flatten.compact.map! do |chain|
            if chain.last_node.resource == endpoint.resource
              puts "closing chain!"
              @closed_chains.push(chain)
              nil
            else
              chain
            end
          end
          
          new_chains = @open_chains.flatten.compact.map do |chain|           
            connections.map do |connection|
              links = connection.links(chain.last_node).select {|link| unvisited?(link) }
              if links.any?
                links.map do |link|
                  # puts "adding #{link} to visited"
                  @visited.push(link.node.resource) unless link.node.resource == @endpoint.resource
                  new_links = chain.links + [link]
                  Chain.new(new_links)
                end
              else
                nil
              end #links.any?
            end #connections.map
          end #open_chains.map!
          @open_chains = new_chains
        end #while
        self
      end
      
      def unvisited?(link)
        !@visited.include?(link.node.resource)
      end
      
      def shortest_chains
        min_size = @closed_chains.sort_by(&:size).first.size
        @closed_chains.select { |x| x.size == min_size }
      end
      
      def directest_chains
        min_spouses =  @closed_chains.map {|x| x.count {|y| y.name == :spouses } }.sort.first
        # @closed_chains.min {|x| x.count {|y| y.name == :spouses } }
        @closed_chains.select {|x| x.count {|y| y.name == :spouses} == min_spouses}
      end
      
      def connections
        @connections ||= CONNECTION_CONFIG.map do |k,v|
          Connection.new(k,v, @visited)
        end
      end
    end
  end
end