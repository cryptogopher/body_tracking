class CreateMeasurements < ActiveRecord::Migration
  def change
    create_table :measurements do |t|
      t.string :name
      t.boolean :hidden
      t.references :source, index: true, foreign_key: true
    end
    add_index :measurements, :source_id
  end
end
