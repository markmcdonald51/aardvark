strands = @chain.inject([[]]) do |memo, link|
  if link.name == :spouses
    memo.push([link])
  else
    memo.last.push(link)
  end
  memo
end

indent = 0
direction = nil
strand_strings = strands.map do |strand|    
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


# strands.map do |strand|
#   strand.inject("") do |output, link|
#     name = "<#{link.node.display_name}>"
#     type = link.name
#     case type
#       when :start, :spouses
#         output = "+" + name
#       when :father, :mother
#         "#{name}-+#{output}"
#       when :children
#         "#{output}-+#{name}"
#       when :siblings
#         position = output.rindex("+")
#         "#{output}\n" + (" " * position) + "L#{name}"
#     end
#   end
# end
# 

