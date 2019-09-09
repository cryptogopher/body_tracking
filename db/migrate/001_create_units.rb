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

        Quantity.create project: nil, domain: :diet, parent: nil, name: "Proteins",
          description: "Total amount of proteins"

        # https://www.fsai.ie/uploadedFiles/Consol_Reg1169_2011.pdf
        # https://www.fsai.ie/legislation/food_legislation/food_information_fic/nutrition_labelling.html
        f = Quantity.create project: nil, domain: :diet, parent: nil, name: "Fats",
          description: "Total lipids, including phospholipids"
        f1 = Quantity.create project: nil, domain: :diet, parent: f, name: "Fatty acids",
          description: ""
        f2 = Quantity.create project: nil, domain: :diet, parent: f1, name: "Saturated",
          description: "Fatty acids without double bond"
        f3 = Quantity.create project: nil, domain: :diet, parent: f1, name: "Unsaturated",
          description: ""
        f4 = Quantity.create project: nil, domain: :diet, parent: f3, name: "Monounsaturated",
          description: "Fatty acids with one cis double bond"
        f5 = Quantity.create project: nil, domain: :diet, parent: f3, name: "Polyunsaturated",
          description: "Fatty acids with two or more cis, cis-methylene interrupted" \
          " double bonds; PUFA"
        f6 = Quantity.create project: nil, domain: :diet, parent: f3, name: "Trans",
          description: "Fatty acids with at least one non-conjugated C-C double bond in the" \
          " trans configuration"
        f7 = Quantity.create project: nil, domain: :diet, parent: f5, name: "Omega-3 (n-3)",
          description: ""
        f8 = Quantity.create project: nil, domain: :diet, parent: f5, name: "Omega-6 (n-6)",
          description: ""
        f9 = Quantity.create project: nil, domain: :diet, parent: f7, name: "ALA 18:3(n-3)",
          description: "alpha-Linolenic acid"
        f10 = Quantity.create project: nil, domain: :diet, parent: f7, name: "EPA 20:5(n-3)",
          description: "eicosapentaenoic acid; icosapentaenoic acid"
        f11 = Quantity.create project: nil, domain: :diet, parent: f7, name: "DHA 22:6(n-3)",
          description: "Docosahexaenoic acid"

        Quantity.create project: nil, domain: :diet, parent: nil, name: "Carbohydrates",
          description: "Total amount of carbohydrates"
      end
      dir.down do
        Unit.where(project: nil).delete_all
      end
    end
  end
end
