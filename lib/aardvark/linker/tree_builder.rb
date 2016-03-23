module Aardvark
  module Linker
    class TreeBuilder
      def self.build(chain)
        temp = []
        # chain.inject do |memo, link|
        #   next_type = link.name
        #   if next_type == :children && memo
        #     if memo.name == :father || memo.nam == :mother
        #       memo.name = :spouses
        #     end
        #   else
        #     temp.push(link)
        #   end
        #   link
        # end
        
        strands = chain.inject([[]]) do |memo, link|
          if link.name == :spouses
            memo.push([link])
          else
            memo.last.push(link)
          end
          memo
        end

        indent = 0
        direction = nil
        chain_direction = nil
        strand_strings = strands.map do |strand|
          old_direction = chain_direction
          strand_type = if (strand.map(&:name) & [:mother, :father]).any?
            :parental
          else
            nil
          end
          
          chain_direction = if (strand_type == :parental)
            :up
          elsif (strand.map(&:name) & [:children]).any?
            :down
          else
            old_direction
          end
          
          if old_direction == :up && chain_direction == :up && strand_type == :parental
            strand.each {|l| (l.name == :father || l.name == :mother) && l.name = :children }
            spouse = strand.shift
            strand.reverse!
            strand.unshift(spouse)
          end
          
          strand.inject("") do |output, link|

            name = "<#{link.node.display_name}>"
            type = link.name
            case type
              when :start, :spouses
                output = name
              when :father, :mother
                if direction == :down || direction == nil 
                  indent = 2
                else
                  indent += 2
                end
                direction = :up
                "#{name}\n#{" " * indent}#{output}"
              when :children
                # binding.pry if name.match("Maria")

                if direction == :up || direction == nil 
                  indent = 2
                else
                  indent += 2
                end
                direction = :down
                "#{output}\n#{" " * indent}#{name}"
              when :siblings
                position = if direction == :up
                  output.index("<")
                else
                  output.rindex("<") 
                end
                direction = nil
                "#{output}\n" + (" " * position) + "#{name}"
            end
            
          end
        end

        output = strand_strings.inject(strand_strings.shift) do |output, string|
          last_line = output.split("\n").last || output
          bracket_pos = last_line.rindex("<") || 0
          line_pos = last_line.length - ((last_line.length - bracket_pos) - 3)
          new_string = string.gsub("\n", "\n#{(" " * bracket_pos)}")
          "#{output}\n#{(" " * line_pos)}||\n#{(" " * bracket_pos)}#{new_string}"
          # "#{output}==#{new_string}"
        end

        print output
      end
    end
  end
end