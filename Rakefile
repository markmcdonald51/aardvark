require "bundler/gem_tasks"
require "active_record"
require 'yaml'
require 'pry'
task :setup do
  config = YAML.load_file("./lib/aardvark/config/database.yml")
  ActiveRecord::Base.establish_connection(config.except("database"))
  ActiveRecord::Base.connection.create_database(config["database"])
  ActiveRecord::Base.establish_connection(config)
  ActiveRecord::Schema.define do  
    create_table "reptiloids", force: true do |t|
      t.string   "resource"
      t.string   "name"
      t.string   "ancestry"
      t.datetime "birth_date"
      t.string "birth_place"
      t.boolean "dead_end"
      t.boolean "done"
      t.integer "parents_found", default: 0
    end
    
    add_index "reptiloids", ["ancestry"], name: "index_employees_on_ancestry", using: :btree    
  end
end