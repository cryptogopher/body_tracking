class CreateSchema <
  (Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2])
  def change
    create_table :quantities do |t|
      t.references :project
      t.integer :domain
      t.string :name
      t.string :description
      # fields for awesome_nested_set
      t.references :parent
      t.integer :lft, null: false, index: true
      t.integer :rgt, null: false, index: true
      # TODO: remove depth (seems to be replaceable by lft)
      t.integer :depth, null: false, default: 0
      t.timestamps null: false
    end

    create_table :formulas do |t|
      t.references :quantity
      t.string :code
      t.boolean :zero_nil
      t.references :unit
      t.timestamps null: false
    end

    create_table :exposures do |t|
      t.references :view, polymorphic: true
      t.references :quantity
    end

    create_table :quantity_values do |t|
      t.string :type
      t.references :registry, polymorphic: true
      t.references :quantity
      t.decimal :value, precision: 12, scale: 6
      t.references :unit
      t.timestamps null: false
    end

    create_table :units do |t|
      t.references :project
      t.string :name
      t.string :shortname
      t.timestamps null: false
    end

    create_table :sources do |t|
      t.references :project
      t.string :name
      t.text :description
      t.timestamps null: false
    end

    create_table :meals do |t|
      t.references :project
      t.text :notes
      t.timestamp :eaten_at
      t.timestamps null: false
    end

    create_table :ingredients do |t|
      t.references :composition, polymorphic: true
      t.references :food
      t.decimal :amount, precision: 12, scale: 6
      t.references :part_of
      t.decimal :ready_ratio, precision: 12, scale: 6
      t.timestamps null: false
    end

    create_table :foods do |t|
      t.references :project
      t.string :name
      t.text :notes
      t.decimal :ref_amount, precision: 12, scale: 6
      t.references :ref_unit
      t.integer :group
      t.references :source
      t.string :source_ident
      # TODO: rename to is_hidden
      t.boolean :hidden
      t.decimal :ready_amount, precision: 12, scale: 6
      t.timestamps null: false
    end

    create_table :measurement_routines do |t|
      t.references :project
      t.string :name
      t.text :description
      t.timestamps null: false
    end

    create_table :measurements do |t|
      t.references :routine
      t.references :source
      t.text :notes
      t.timestamp :taken_at
      t.timestamps null: false
    end

    create_table :goals do |t|
      t.references :project
      t.boolean :is_binding
      t.string :name
      t.text :description
      t.timestamps null: false
    end

    create_table :targets do |t|
      t.references :goal
      t.references :quantity
      t.references :item, polymorphic: true
      t.string :scope
      t.date :effective_from
      t.timestamps null: false
    end
  end
end
