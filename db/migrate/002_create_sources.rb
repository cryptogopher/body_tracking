class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.references :project, index: true, foreign_key: true
      t.string :name
      t.text :description
    end
    add_index :sources, :project_id
  end
end
