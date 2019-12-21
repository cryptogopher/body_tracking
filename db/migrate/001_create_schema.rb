class CreateSchema < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.references :project
      t.string :name
      t.string :shortname
      t.timestamps null: false
    end

    create_table :quantities do |t|
      t.references :project
      t.integer :domain
      t.string :name
      t.string :formula
      t.string :description
      # fields for awesome_nested_set
      t.references :parent
      t.integer :lft, null: false, index: true
      t.integer :rgt, null: false, index: true
      t.timestamps null: false
    end

    create_table :column_views do |t|
      t.references :project
      t.string :name
      t.integer :domain
    end

    create_table :column_views_quantities do |t|
      t.references :column_view
      t.references :quantity
    end

    create_table :sources do |t|
      t.references :project
      t.string :name
      t.text :description
      t.timestamps null: false
    end

    create_table :ingredients do |t|
      t.references :project
      t.string :name
      t.decimal :ref_amount, precision: 12, scale: 6
      t.references :ref_unit
      t.integer :group
      t.references :source
      t.string :source_ident
      t.boolean :hidden
      t.timestamps null: false
    end

    create_table :nutrients do |t|
      t.references :ingredient
      t.references :quantity
      t.decimal :amount, precision: 12, scale: 6
      t.references :unit
      t.timestamps null: false
    end

    create_table :measurements do |t|
      t.references :project
      t.string :name
      t.references :source
      t.boolean :hidden
      t.timestamp :taken_at
      t.timestamps null: false
    end

    create_table :readouts do |t|
      t.references :measurement
      t.references :quantity
      t.decimal :value, precision: 12, scale: 6
      t.references :unit
      t.timestamps null: false
    end
  end
end
