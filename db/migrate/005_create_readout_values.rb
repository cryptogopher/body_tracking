class CreateReadoutValues < ActiveRecord::Migration
  def change
    create_table :readout_values do |t|
      t.references :readout, index: true, foreign_key: true
      t.decimal :value
      t.timestamp :taken_at
    end
    add_index :readout_values, :readout_id
  end
end
