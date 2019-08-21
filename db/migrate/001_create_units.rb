class CreateUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.references :project
      t.string :name
      t.string :shortname
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
