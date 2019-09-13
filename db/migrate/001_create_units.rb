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
      t.references :project
      t.string :name
      t.decimal :ref_amount
      t.references :ref_unit
      t.integer :group
      t.references :source
      t.boolean :hidden
    end

    create_table :nutrients do |t|
      t.references :ingredient
      t.references :quantity
      t.references :unit
      t.decimal :amount
    end

    reversible do |dir|
      dir.up do
        Unit.create project: nil, shortname: "%", name: "percent"
        Unit.create project: nil, shortname: "g", name: "gram"
        Unit.create project: nil, shortname: "kg", name: "kilogram"

        # https://www.fsai.ie/uploadedFiles/Consol_Reg1169_2011.pdf
        # https://www.fsai.ie/legislation/food_legislation/food_information_fic/nutrition_labelling.html
        Quantity.create project: nil, domain: :diet, parent: nil, name: "Proteins",
          description: "Total amount of proteins"

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
          description: "Eicosapentaenoic acid; also icosapentaenoic acid"
        f11 = Quantity.create project: nil, domain: :diet, parent: f7, name: "DHA 22:6(n-3)",
          description: "Docosahexaenoic acid"

        c1 = Quantity.create project: nil, domain: :diet, parent: nil, name: "Carbohydrates",
          description: "Total amount of carbohydrates"
        c2 = Quantity.create project: nil, domain: :diet, parent: c1, name: "Digestible",
          description: ""
        c3 = Quantity.create project: nil, domain: :diet, parent: c2, name: "Sugars",
          description: "Monosaccharides and disaccharides, excluding polyols"
        c4 = Quantity.create project: nil, domain: :diet, parent: c3, name: "Monosaccharides",
          description: ""
        c5 = Quantity.create project: nil, domain: :diet, parent: c4, name: "Glucose",
          description: ""
        c6 = Quantity.create project: nil, domain: :diet, parent: c4, name: "Fructose",
          description: ""
        c7 = Quantity.create project: nil, domain: :diet, parent: c3, name: "Disaccharides",
          description: ""
        c8 = Quantity.create project: nil, domain: :diet, parent: c7, name: "Sucrose",
          description: ""
        c9 = Quantity.create project: nil, domain: :diet, parent: c7, name: "Lactose",
          description: ""
        c10 = Quantity.create project: nil, domain: :diet, parent: c2, name: "Polyols",
          description: "Alcohols containing more than 2 hydroxyl groups"
        c11 = Quantity.create project: nil, domain: :diet, parent: c2,
          name: "Polysaccharides", description: ""
        c12 = Quantity.create project: nil, domain: :diet, parent: c11, name: "Starch",
          description: ""
        c13 = Quantity.create project: nil, domain: :diet, parent: c1, name: "Indigestible",
          description: ""
        c14 = Quantity.create project: nil, domain: :diet, parent: c13, name: "Fibre",
          description: "Carbohydrate polymers with 3 or more monomeric units, which are" \
          " neither digested nor absorbed in the human small intestine"

        m1 = Quantity.create project: nil, domain: :diet, parent: nil, name: "Minerals",
          description: ""
        m2 = Quantity.create project: nil, domain: :diet, parent: m1, name: "Salt",
          description: "Sodium chloride"

        v1 = Quantity.create project: nil, domain: :diet, parent: nil, name: "Vitamins",
          description: ""
        v2 = Quantity.create project: nil, domain: :diet, parent: v1, name: "Vitamin A",
          description: ""
        v3 = Quantity.create project: nil, domain: :diet, parent: v2, name: "Retinol (A1)",
          description: ""
        v4 = Quantity.create project: nil, domain: :diet, parent: v1, name: "Provitamin A",
          description: ""
        v5 = Quantity.create project: nil, domain: :diet, parent: v4, name: "beta-Carotene",
          description: ""
        v6 = Quantity.create project: nil, domain: :diet, parent: v1, name: "Vitamin B",
          description: ""
        v7 = Quantity.create project: nil, domain: :diet, parent: v6, name: "Thiamine (B1)",
          description: ""
        v8 = Quantity.create project: nil, domain: :diet, parent: v6, name: "Riboflavin (B2)",
          description: "Vitamin G"
        v9 = Quantity.create project: nil, domain: :diet, parent: v6, name: "Vitamin B3",
          description: "Vitamin PP"
        v10 = Quantity.create project: nil, domain: :diet, parent: v9, name: "Niacin",
          description: "Nicotinic acid"
        v11 = Quantity.create project: nil, domain: :diet, parent: v6, name: "Vitamin B5",
          description: "Pantothenic acid"
        v12 = Quantity.create project: nil, domain: :diet, parent: v6, name: "Vitamin B6",
          description: ""
        v13 = Quantity.create project: nil, domain: :diet, parent: v6, name: "Biotin (B7)",
          description: "Vitamin H, also coenzyme R"
        v14 = Quantity.create project: nil, domain: :diet, parent: v6, name: "Folate",
          description: "Includes: folic acid, folacin and vitamin B9"
        v15 = Quantity.create project: nil, domain: :diet, parent: v14, name: "Vitamin B9",
          description: ""
        v16 = Quantity.create project: nil, domain: :diet, parent: v6,
          name: "Cobalamin (B12)", description: ""
        v17 = Quantity.create project: nil, domain: :diet, parent: v1, name: "Vitamin C",
          description: ""
        v18 = Quantity.create project: nil, domain: :diet, parent: v1, name: "Vitamin D",
          description: "Calciferol"
        v19 = Quantity.create project: nil, domain: :diet, parent: v18,
          name: "Cholecalciferol (D3)", description: ""
        v20 = Quantity.create project: nil, domain: :diet, parent: v1, name: "Vitamin E",
          description: ""
        v21 = Quantity.create project: nil, domain: :diet, parent: v1, name: "Vitamin K",
          description: ""
      end
      dir.down do
        Unit.where(project: nil).delete_all
        Quantity.where(project: nil).delete_all
      end
    end
  end
end
