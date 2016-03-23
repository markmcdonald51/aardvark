module Aardvark
  module Crawlers
    class DbpFamilyWebBuilder < FamilyWebBuilder
      def run(root, sex)        
        repo.create(resource: root, sex: sex)
        while candidates.any?
          candidates.each do |c|
            build_relative(c, :mother) unless c.mother_id
            build_relative(c, :father) unless c.father_id
            build_spouses(c)
            build_children(c)
            c.update_attribute(:done, true)       
          end
        end
      end
      
      def build_relative(person, relation)
        attribute_sets = relative_fetcher.fetch(person.resource, relation)
        attribute_sets.each do |attributes|
          if attributes.compact.empty?
            break
            return true
          end
          # puts "==>#{person.name} - #{__method__} - attributes: #{attributes}"
          relative = build_person(attributes)
          if relative.done?
            break
            return true
          end
          relative.save!
          if person.send(relation)
            if relation == :mother
              relation = :father
            else
              relation = :mother
            end
          else
            person.update_attributes!(relation => relative)      
          end
        end
      end
      
    end
  end
end