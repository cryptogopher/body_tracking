class CreateUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.references :project, index: true, foreign_key: true
      t.string :name
      t.string :shortname
    end
    add_index :units, :project_id

    create_table :quantities do |t|
      t.references :project, index: true, foreign_key: true
      t.string :name
      t.string :description
      t.integer :domain
    end
    add_index :quantities, :project_id

    create_table :ingredients do |t|
      t.string :name
      t.references :ref_unit, index: true, foreign_key: true
      t.decimal :ref_amount
      t.boolean :hidden
      t.references :source, index: true, foreign_key: true
      t.integer :group
    end
    add_index :ingredients, :ref_unit_id
    add_index :ingredients, :source_id

    reversible do |dir|
      dir.up do
        Unit.create project: nil, shortname: "%", name: "percent"
        Unit.create project: nil, shortname: "g", name: "gram"
        Unit.create project: nil, shortname: "kg", name: "kilogram"
      end
      dir.down do
        Unit.where(project: nil).delete_all
      end
    end
  end
end
