module Aardvark
  module Crawlers
    class FamilyWebBuilder
      attr_reader :relative_fetcher, :dbpedia_relative_fetcher
      
      def initialize(relative_fetcher)
        @relative_fetcher = relative_fetcher
      end
      
      def repo
        Shapeshifter
      end
      
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
      
      def candidates
        repo.where(done: false)
      end
      
      def build_person(attributes)
        resource = attributes[0].split("/").last
        record = repo.find_by(resource: resource) || repo.new(resource: resource, name: attributes[1], sex: attributes[2])
      end
      
      def build_spouses(person)
        attribute_sets = relative_fetcher.fetch(person.resource, :spouse) 
        attribute_sets.each do |attributes|
          # puts "==>#{person.name} - #{__method__} - attributes: #{attributes}"
          relative = build_person(attributes)
          
          if relative.done?
            true
          else
            relative.save!
            Marriage.create(partner_1: person, partner_2: relative) unless Marriage.exists?(relative, person)
          end
        end
      end
      
      def build_children(person)
        attribute_sets = relative_fetcher.fetch(person.resource, :child)
        attribute_sets.each do |attributes|
          # puts "==>#{person.name} - #{__method__} - attributes: #{attributes}"
          relative = build_person(attributes)
          if relative.done?
            true
          else
            if person.sex == "F"
              relative.mother = person
            elsif person.sex == "M"
              relative.father = person
            elsif relative.mother
              relative.father = person
            else
              relative.mother = person
            end
          
            r=relative.save!
          end
        end
      end
      
      def build_relative(person, relation)
        attributes = relative_fetcher.fetch(person.resource, relation).flatten
        return true if attributes.compact.empty?
        
        # puts "==>#{person.name} - #{__method__} - attributes: #{attributes}"
        relative = build_person(attributes)
        return true if relative.done?
        relative.save!
        person.update_attributes!(relation => relative)      
      end
    end
  end
end