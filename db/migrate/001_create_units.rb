class CreateUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.references :project
      t.string :name
      t.string :shortname
    end

    create_table :quantities do |t|
      t.references :project
      t.string :name
      t.string :description
      t.integer :domain
      # fields for awesome_nested_set
      t.references :parent
      t.integer :lft, :null => false, :index => true
      t.integer :rgt, :null => false, :index => true
    end

    create_table :ingredients do |t|
      t.string :name
      t.references :ref_unit
      t.decimal :ref_amount
      t.boolean :hidden
      t.references :source
      t.integer :group
    end

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
