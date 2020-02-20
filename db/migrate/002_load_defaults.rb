class LoadDefaults < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        Unit.create project: nil, shortname: "g", name: "gram"
        Unit.create project: nil, shortname: "mg", name: "milligram"
        Unit.create project: nil, shortname: "ug", name: "microgram"
        Unit.create project: nil, shortname: "kg", name: "kilogram"
        Unit.create project: nil, shortname: "kcal", name: "kilocalorie"
        Unit.create project: nil, shortname: "%", name: "percent"

        # https://www.fsai.ie/uploadedFiles/Consol_Reg1169_2011.pdf
        # https://www.fsai.ie/legislation/food_legislation/food_information_fic/nutrition_labelling.html
        e1 = Quantity.create project: nil, domain: :diet, parent: nil, name: "Energy",
          description: "Total energy"
        e2 = Quantity.create project: nil, domain: :diet, parent: e1, name: "Calculated",
          description: "Total energy calculated from macronutrients"

        p1 = Quantity.create project: nil, domain: :diet, parent: nil, name: "Proteins",
          description: "Total amount of proteins"

        f1 = Quantity.create project: nil, domain: :diet, parent: nil, name: "Fats",
          description: "Total lipids, including phospholipids"
        f2 = Quantity.create project: nil, domain: :diet, parent: f1, name: "Fatty acids",
          description: ""
        f3 = Quantity.create project: nil, domain: :diet, parent: f2, name: "Saturated",
          description: "Fatty acids without double bond"
        f4 = Quantity.create project: nil, domain: :diet, parent: f2, name: "Unsaturated",
          description: ""
        f5 = Quantity.create project: nil, domain: :diet, parent: f4, name: "Monounsaturated",
          description: "Fatty acids with one cis double bond"
        f6 = Quantity.create project: nil, domain: :diet, parent: f4, name: "Polyunsaturated",
          description: "Fatty acids with two or more cis, cis-methylene interrupted" \
          " double bonds; PUFA"
        f7 = Quantity.create project: nil, domain: :diet, parent: f4, name: "Trans",
          description: "Fatty acids with at least one non-conjugated C-C double bond in the" \
          " trans configuration"
        f8 = Quantity.create project: nil, domain: :diet, parent: f6, name: "Omega-3 (n-3)",
          description: ""
        f9 = Quantity.create project: nil, domain: :diet, parent: f6, name: "Omega-6 (n-6)",
          description: ""
        f10 = Quantity.create project: nil, domain: :diet, parent: f8, name: "ALA 18:3(n-3)",
          description: "alpha-Linolenic acid"
        f11 = Quantity.create project: nil, domain: :diet, parent: f8, name: "EPA 20:5(n-3)",
          description: "Eicosapentaenoic acid; also icosapentaenoic acid"
        f12 = Quantity.create project: nil, domain: :diet, parent: f8, name: "DHA 22:6(n-3)",
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

        b1 = Quantity.create project: nil, domain: :measurement, parent: nil,
          name: "Body composition", description: ""
        b2 = Quantity.create project: nil, domain: :measurement, parent: b1,
          name: "Weight", description: "Total weight"
        b3 = Quantity.create project: nil, domain: :measurement, parent: b2,
          name: "Fat", description: "Fat weight"
        b4 = Quantity.create project: nil, domain: :measurement, parent: b2,
          name: "Muscle", description: "Muscle weight"
        b5 = Quantity.create project: nil, domain: :measurement, parent: b1,
          name: "Composition", description: ""
        b6 = Quantity.create project: nil, domain: :measurement, parent: b5,
          name: "% fat", description: "Fat as a % of total body weight"
        b7 = Quantity.create project: nil, domain: :measurement, parent: b5,
          name: "% muscle", description: "Muscle as a % of total body weight"
        b8 = Quantity.create project: nil, domain: :measurement, parent: b1,
          name: "RM", description: "Resting metabolism"
        b9 = Quantity.create project: nil, domain: :measurement, parent: b1,
          name: "VF", description: "Visceral fat"

        # Formulas go at the and to make sure dependencies exist
        e2.create_formula code: "4*Proteins + 9*Fats + 4*Carbohydrates", zero_nil: true
        b3.create_formula code: "'% fat' * 'Weight'", zero_nil: true

        Source.create project: nil, name: "nutrition label",
          description: "nutrition facts taken from package nutrition label"
      end

      dir.down do
        Source.where(project: nil).delete_all
        Quantity.where(project: nil).delete_all
        Unit.where(project: nil).delete_all
      end
    end
  end
end
