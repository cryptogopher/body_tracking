class CreateReadouts < ActiveRecord::Migration
  def change
    create_table :readouts do |t|
      t.references :measurement, index: true, foreign_key: true
      t.references :quantity, index: true, foreign_key: true
      t.references :unit, index: true, foreign_key: true
    end
    add_index :readouts, :measurement_id
    add_index :readouts, :quantity_id
    add_index :readouts, :unit_id
  end
end
