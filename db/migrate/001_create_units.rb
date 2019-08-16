class CreateUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.references :project
      t.string :name
      t.string :shortname
      t.integer :group
    end

    reversible do |dir|
      dir.up do
        Unit.create project: nil, shortname: "", name: "count", group: :number
        Unit.create project: nil, shortname: "%", name: "percent", group: :share
        Unit.create project: nil, shortname: "g", name: "gram", group: :mass
        Unit.create project: nil, shortname: "kg", name: "kilogram", group: :mass
      end

      dir.down do
        Unit.delete_all
      end
    end
  end
end
