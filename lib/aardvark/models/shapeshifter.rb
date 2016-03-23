class Marriage < ActiveRecord::Base
  belongs_to :partner_1, class_name: "Shapeshifter"
  belongs_to :partner_2, class_name: "Shapeshifter"
  
  def self.exists?(person_1, person_2)
    where("(partner_1_id = #{person_1.id} and partner_2_id = #{person_2.id}) OR (partner_1_id = #{person_2.id} and partner_2_id = #{person_1.id})").any?
  end
end

class Shapeshifter < ActiveRecord::Base
  class << self
    def build_table
      unless ActiveRecord::Base.connection.table_exists? :shapeshifters
        ActiveRecord::Schema.define do  
          create_table "shapeshifters", force: true do |t|
            t.string  "resource"
            t.string  "name"
            t.string  "sex"
            t.integer "mother_id"
            t.integer "father_id"
            t.datetime "birth_date"
            t.string "birth_place"
            t.string "birth_place_geo"
            t.string "type"
            t.boolean "done", default: false
          end
        
          create_table "marriages", force: true do |t|
            t.integer "partner_1_id"
            t.integer "partner_2_id"
          end
          
          add_index :shapeshifters, :mother_id
          add_index :shapeshifters, :father_id
          add_index :shapeshifters, :resource
          add_index :marriages, [:partner_1_id, :partner_2_id]
          
        end
      end
    end
    
    def reset
      ActiveRecord::Base.connection.drop_table :shapeshifters
      build_table
    end
    
    def counter
      @@counter ||= 0
      @@counter += 1
    end
    
    def search(str)
      where("name ilike ?", "%#{str}%")
    end
  end

  belongs_to :mother, class_name: self
  belongs_to :father, class_name: self
  
  scope :spouses, ->(person) { where("id in
    (select partner_1_id from marriages where partner_2_id = #{person.id}
    union
    select partner_2_id from marriages where partner_1_id = #{person.id}
    )")
  }
  
  scope :laypeople, -> { where("
    name not ilike ? 
    and name not ilike ? 
    and name not ilike ? 
    and name not ilike ? 
    and name not ilike ? 
    and name not ilike ? 
    and name not ilike ?", 
    "%prince%", "%king%", "%duke%", "%duchess%", "%count%","%lord%", "%_of_%" )}
  after_create :put_count
  
  def spouses
    self.class.spouses(self)
  end
  
  def parents
    [father, mother]
  end
  
  def generation
    count = 1
    gen = parents.flatten.compact
    
    while gen.any?
      gen = gen.map(&:parents).flatten.compact
      count += 1
    end
    count
  end
  
  def children
    self.class.where("mother_id = #{self.id} or father_id = #{self.id}")
  end
  
  def siblings
    self.class.where("(mother_id = #{self.mother_id || 0} or father_id = #{self.father_id || 0}) and id != #{self.id}")  
  end
  
  def put_count
    puts self.class.counter.to_s + ":#{self.resource}"
  end
  
  def display_name
    URI.decode(self.name[29..-1]).gsub("_", " ")
  rescue
    binding.pry
  end
end

