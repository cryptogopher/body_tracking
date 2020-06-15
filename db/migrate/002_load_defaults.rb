class LoadDefaults < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        u_a = Unit.create project: nil, shortname: "g", name: "gram"
        u_aa = Unit.create project: nil, shortname: "mg", name: "milligram"
        u_ab = Unit.create project: nil, shortname: "kg", name: "kilogram"
        u_ac = Unit.create project: nil, shortname: "ug", name: "microgram"
        u_b = Unit.create project: nil, shortname: "kcal", name: "kilocalorie"
        u_c = Unit.create project: nil, shortname: "%", name: "percent"

        # https://www.fsai.ie/uploadedFiles/Consol_Reg1169_2011.pdf
        # https://www.fsai.ie/legislation/food_legislation/food_information_fic/nutrition_labelling.html
        e_a = Quantity.create project: nil, domain: :diet, parent: nil,
          name: "Energy", description: "Total energy"
        e_aa = Quantity.create project: nil, domain: :diet, parent: e_a,
          name: "calculated", description: "Total energy calculated from macronutrients"
        e_ab = Quantity.create project: nil, domain: :diet, parent: e_a,
          name: "as %RM", description: "Total energy percent value relative to current" \
          " resting metabolism"
        e_ac = Quantity.create domain: :diet, parent: e_a,
          name: "proteins", description: "Calculated proteins energy"
        e_aca = Quantity.create domain: :diet, parent: e_ac,
          name: "as %RM", description: ""
        e_ad = Quantity.create domain: :diet, parent: e_a,
          name: "fats", description: "Calculated fats energy"
        e_ada = Quantity.create domain: :diet, parent: e_ad,
          name: "as %RM", description: ""
        e_ae = Quantity.create domain: :diet, parent: e_a,
          name: "carbs", description: "Calculated carbs energy"
        e_aea = Quantity.create domain: :diet, parent: e_ae,
          name: "as %RM", description: ""

        p_a = Quantity.create project: nil, domain: :diet, parent: nil,
          name: "Proteins", description: "Total amount of proteins"

        f_a = Quantity.create project: nil, domain: :diet, parent: nil,
          name: "Fats", description: "Total lipids, including phospholipids"
        f_aa = Quantity.create project: nil, domain: :diet, parent: f_a,
          name: "Fatty acids", description: ""
        f_aaa = Quantity.create project: nil, domain: :diet, parent: f_aa,
          name: "Saturated", description: "Fatty acids without double bond"
        f_aab = Quantity.create project: nil, domain: :diet, parent: f_aa,
          name: "Unsaturated", description: ""
        f_aaba = Quantity.create project: nil, domain: :diet, parent: f_aab,
          name: "Monounsaturated", description: "Fatty acids with one cis double bond"
        f_aabb = Quantity.create project: nil, domain: :diet, parent: f_aab,
          name: "Polyunsaturated", description: "Fatty acids with two or more cis," \
          " cis-methylene interrupted double bonds; PUFA"
        f_aabba = Quantity.create project: nil, domain: :diet, parent: f_aabb,
          name: "Omega-3 (n-3)", description: ""
        f_aabbaa = Quantity.create project: nil, domain: :diet, parent: f_aabba,
          name: "ALA 18:3(n-3)", description: "alpha-Linolenic acid"
        f_aabbab = Quantity.create project: nil, domain: :diet, parent: f_aabba,
          name: "EPA 20:5(n-3)", description: "Eicosapentaenoic acid; also icosapentaenoic" \
          " acid"
        f_aabbac = Quantity.create project: nil, domain: :diet, parent: f_aabba,
          name: "DHA 22:6(n-3)", description: "Docosahexaenoic acid"
        f_aabbb = Quantity.create project: nil, domain: :diet, parent: f_aabb,
          name: "Omega-6 (n-6)", description: ""
        f_aabc = Quantity.create project: nil, domain: :diet, parent: f_aab,
          name: "Trans", description: "Fatty acids with at least one non-conjugated C-C" \
          " double bond in the trans configuration"

        c_a = Quantity.create project: nil, domain: :diet, parent: nil,
          name: "Carbs", description: "Total amount of carbohydrates"
        c_aa = Quantity.create project: nil, domain: :diet, parent: c_a,
          name: "Digestible", description: ""
        c_aaa = Quantity.create project: nil, domain: :diet, parent: c_aa,
          name: "Sugars", description: "Monosaccharides and disaccharides, excluding polyols"
        c_aaaa = Quantity.create project: nil, domain: :diet, parent: c_aaa,
          name: "Monosaccharides", description: ""
        c_aaaaa = Quantity.create project: nil, domain: :diet, parent: c_aaaa,
          name: "Glucose", description: ""
        c_aaaab = Quantity.create project: nil, domain: :diet, parent: c_aaaa,
          name: "Fructose", description: ""
        c_aaab = Quantity.create project: nil, domain: :diet, parent: c_aaa,
          name: "Disaccharides", description: ""
        c_aaaba = Quantity.create project: nil, domain: :diet, parent: c_aaab,
          name: "Sucrose", description: ""
        c_aaabb = Quantity.create project: nil, domain: :diet, parent: c_aaab,
          name: "Lactose", description: ""
        c_aab = Quantity.create project: nil, domain: :diet, parent: c_aa,
          name: "Polyols", description: "Alcohols containing more than 2 hydroxyl groups"
        c_aac = Quantity.create project: nil, domain: :diet, parent: c_aa,
          name: "Polysaccharides", description: ""
        c_aaca = Quantity.create project: nil, domain: :diet, parent: c_aac,
          name: "Starch", description: ""
        c_ab = Quantity.create project: nil, domain: :diet, parent: c_a,
          name: "Indigestible", description: ""
        c_aba = Quantity.create project: nil, domain: :diet, parent: c_ab,
          name: "Fibre", description: "Carbohydrate polymers with 3 or more monomeric" \
          " units, which are neither digested nor absorbed in the human small intestine"

        m_a = Quantity.create project: nil, domain: :diet, parent: nil,
          name: "Minerals", description: ""
        m_aa = Quantity.create project: nil, domain: :diet, parent: m_a,
          name: "Salt", description: "Sodium chloride"

        v_a = Quantity.create project: nil, domain: :diet, parent: nil,
          name: "Vitamins", description: ""
        v_aa = Quantity.create project: nil, domain: :diet, parent: v_a,
          name: "Vitamin A", description: ""
        v_aaa = Quantity.create project: nil, domain: :diet, parent: v_aa,
          name: "Retinol (A1)", description: ""
        v_ab = Quantity.create project: nil, domain: :diet, parent: v_a,
          name: "Provitamin A", description: ""
        v_aba = Quantity.create project: nil, domain: :diet, parent: v_ab,
          name: "beta-Carotene", description: ""
        v_ac = Quantity.create project: nil, domain: :diet, parent: v_a,
          name: "Vitamin B", description: ""
        v_aca = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Thiamine (B1)", description: ""
        v_acb = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Riboflavin (B2)", description: "Vitamin G"
        v_acc = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Vitamin B3", description: "Vitamin PP"
        v_acca = Quantity.create project: nil, domain: :diet, parent: v_acc,
          name: "Niacin", description: "Nicotinic acid"
        v_acd = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Vitamin B5", description: "Pantothenic acid"
        v_ace = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Vitamin B6", description: ""
        v_acf = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Biotin (B7)", description: "Vitamin H, also coenzyme R"
        v_acg = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Folate", description: "Includes: folic acid, folacin and vitamin B9"
        v_acga = Quantity.create project: nil, domain: :diet, parent: v_acg,
          name: "Vitamin B9", description: ""
        v_ach = Quantity.create project: nil, domain: :diet, parent: v_ac,
          name: "Cobalamin (B12)", description: ""
        v_ad = Quantity.create project: nil, domain: :diet, parent: v_a,
          name: "Vitamin C", description: ""
        v_ae = Quantity.create project: nil, domain: :diet, parent: v_a,
          name: "Vitamin D", description: "Calciferol"
        v_aea = Quantity.create project: nil, domain: :diet, parent: v_ae,
          name: "Cholecalciferol (D3)", description: ""
        v_af = Quantity.create project: nil, domain: :diet, parent: v_a,
          name: "Vitamin E", description: ""
        v_ag = Quantity.create project: nil, domain: :diet, parent: v_a,
          name: "Vitamin K", description: ""

        b_a = Quantity.create project: nil, domain: :measurement, parent: nil,
          name: "Body composition", description: ""
        b_aa = Quantity.create project: nil, domain: :measurement, parent: b_a,
          name: "Weight", description: "Total weight"
        b_aaa = Quantity.create project: nil, domain: :measurement, parent: b_aa,
          name: "Fat", description: "Fat weight"
        b_aab = Quantity.create project: nil, domain: :measurement, parent: b_aa,
          name: "Muscle", description: "Muscle weight"
        b_ab = Quantity.create project: nil, domain: :measurement, parent: b_a,
          name: "Composition", description: ""
        b_aba = Quantity.create project: nil, domain: :measurement, parent: b_ab,
          name: "% fat", description: "Fat as a % of total body weight"
        b_abb = Quantity.create project: nil, domain: :measurement, parent: b_ab,
          name: "% muscle", description: "Muscle as a % of total body weight"
        b_ac = Quantity.create project: nil, domain: :measurement, parent: b_a,
          name: "RM", description: "Resting metabolism"
        b_ad = Quantity.create project: nil, domain: :measurement, parent: b_a,
          name: "VF", description: "Visceral fat"

        # Formulas go at the and to make sure dependencies exist
        e_aa.create_formula zero_nil: true, unit: u_b,
          code: "4*Proteins + 9*Fats + 4*Carbs + 2*Fibre"
        e_ab.create_formula zero_nil: true, unit: u_c,
          code: "100*Energy/RM.lastBefore(Meal.eaten_at||Meal.created_at)"
        e_ac.create_formula zero_nil: true, unit: u_b,
          code: "4*Proteins"
        e_aca.create_formula zero_nil: true, unit: u_c,
          code: "100*proteins/RM.lastBefore(Meal.eaten_at||Meal.created_at)"
        e_ad.create_formula zero_nil: true, unit: u_b,
          code: "4*Fats"
        e_ada.create_formula zero_nil: true, unit: u_c,
          code: "100*fats/RM.lastBefore(Meal.eaten_at||Meal.created_at)"
        e_ae.create_formula zero_nil: true, unit: u_b,
          code: "4*Carbs"
        e_aea.create_formula zero_nil: true, unit: u_c,
          code: "100*carbs/RM.lastBefore(Meal.eaten_at||Meal.created_at)"

        b_aaa.create_formula zero_nil: true, unit: u_ab,
          code: "'% fat' * Weight"

        s_a = Source.create project: nil, name: "nutrition label",
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
