# Formulas will be deleted as dependent on Quantities
[Source, Quantity, Unit].each { |model| model.defaults.delete_all }

# Units
u_a  = Unit.create shortname: "g",    name: "gram"
u_aa = Unit.create shortname: "ug",   name: "microgram"
u_ab = Unit.create shortname: "mg",   name: "milligram"
u_ac = Unit.create shortname: "kg",   name: "kilogram"
u_b  = Unit.create shortname: "kcal", name: "kilocalorie"
u_c  = Unit.create shortname: "%",    name: "percent"

# Quantities
# https://www.fsai.ie/uploadedFiles/Consol_Reg1169_2011.pdf
# https://www.fsai.ie/legislation/food_legislation/food_information_fic/nutrition_labelling.html
# -> Energy
e_a      = Quantity.create name: "Energy",          domain: :diet, parent: nil,
                             description: "Total energy"
e_aa     = Quantity.create name: "calculated",      domain: :diet, parent: e_a,
                             description: "Total energy calculated from macronutrients"
e_ab     = Quantity.create name: "as %RM",          domain: :diet, parent: e_a,
                             description: "Total energy percent value relative to current" \
                                          " resting metabolism"
e_ac     = Quantity.create name: "proteins",        domain: :diet, parent: e_a,
                             description: "Calculated proteins energy"
e_aca    = Quantity.create name: "as %RM",          domain: :diet, parent: e_ac,
                             description: ""
e_ad     = Quantity.create name: "fats",            domain: :diet, parent: e_a,
                             description: "Calculated fats energy"
e_ada    = Quantity.create name: "as %RM",          domain: :diet, parent: e_ad,
                             description: ""
e_ae     = Quantity.create name: "carbs",           domain: :diet, parent: e_a,
                             description: "Calculated carbs energy"
e_aea    = Quantity.create name: "as %RM",          domain: :diet, parent: e_ae,
                             description: ""

# -> Proteins
p_a      = Quantity.create name: "Proteins",        domain: :diet, parent: nil,
                             description: "Total amount of proteins"

# -> Fats
f_a      = Quantity.create name: "Fats",            domain: :diet, parent: nil,
                             description: "Total lipids, including phospholipids"
f_aa     = Quantity.create name: "Fatty acids",     domain: :diet, parent: f_a,
                             description: ""
f_aaa    = Quantity.create name: "Saturated",       domain: :diet, parent: f_aa,
                             description: "Fatty acids without double bond"
f_aab    = Quantity.create name: "Unsaturated",     domain: :diet, parent: f_aa,
                             description: ""
f_aaba   = Quantity.create name: "Monounsaturated", domain: :diet, parent: f_aab,
                             description: "Fatty acids with one cis double bond"
f_aabb   = Quantity.create name: "Polyunsaturated", domain: :diet, parent: f_aab,
                             description: "Fatty acids with two or more cis, cis-methylene" \
                                          " interrupted double bonds; PUFA"
f_aabba  = Quantity.create name: "Omega-3 (n-3)",   domain: :diet, parent: f_aabb,
                             description: ""
f_aabbaa = Quantity.create name: "ALA 18:3(n-3)",   domain: :diet, parent: f_aabba,
                             description: "alpha-Linolenic acid"
f_aabbab = Quantity.create name: "EPA 20:5(n-3)",   domain: :diet, parent: f_aabba,
                             description: "Eicosapentaenoic acid; also icosapentaenoic acid"
f_aabbac = Quantity.create name: "DHA 22:6(n-3)",   domain: :diet, parent: f_aabba,
                             description: "Docosahexaenoic acid"
f_aabbb  = Quantity.create name: "Omega-6 (n-6)",   domain: :diet, parent: f_aabb,
                             description: ""
f_aabc   = Quantity.create name: "Trans",           domain: :diet, parent: f_aab,
                             description: "Fatty acids with at least one non-conjugated C-C" \
                                          " double bond in the trans configuration"

# -> Carbs
c_a      = Quantity.create name: "Carbs",           domain: :diet, parent: nil,
                             description: "Total amount of carbohydrates"
c_aa     = Quantity.create name: "Digestible",      domain: :diet, parent: c_a,
                             description: ""
c_aaa    = Quantity.create name: "Sugars",          domain: :diet, parent: c_aa,
                             description: "Monosaccharides and disaccharides, excluding" \
                                          " polyols"
c_aaaa   = Quantity.create name: "Monosaccharides", domain: :diet, parent: c_aaa,
                             description: ""
c_aaaaa  = Quantity.create name: "Glucose",         domain: :diet, parent: c_aaaa,
                             description: ""
c_aaaab  = Quantity.create name: "Fructose",        domain: :diet, parent: c_aaaa,
                             description: ""
c_aaab   = Quantity.create name: "Disaccharides",   domain: :diet, parent: c_aaa,
                             description: ""
c_aaaba  = Quantity.create name: "Sucrose",         domain: :diet, parent: c_aaab,
                             description: ""
c_aaabb  = Quantity.create name: "Lactose",         domain: :diet, parent: c_aaab,
                             description: ""
c_aab    = Quantity.create name: "Polyols",         domain: :diet, parent: c_aa,
                             description: "Alcohols containing more than 2 hydroxyl groups"
c_aac    = Quantity.create name: "Polysaccharides", domain: :diet, parent: c_aa,
                             description: ""
c_aaca   = Quantity.create name: "Starch",          domain: :diet, parent: c_aac,
                             description: ""
c_ab     = Quantity.create name: "Indigestible",    domain: :diet, parent: c_a,
                             description: ""
c_aba    = Quantity.create name: "Fibre",           domain: :diet, parent: c_ab,
                             description: "Carbohydrate polymers with 3 or more monomeric" \
                                          " units, which are neither digested nor absorbed" \
                                          " in the human small intestine"

# -> Minerals
m_a      = Quantity.create name: "Minerals",        domain: :diet, parent: nil,
                             description: ""
m_aa     = Quantity.create name: "Salt",            domain: :diet, parent: m_a,
                             description: "Sodium chloride"

# -> Vitamins
v_a      = Quantity.create name: "Vitamins",             domain: :diet, parent: nil,
                             description: ""
v_aa     = Quantity.create name: "Vitamin A",            domain: :diet, parent: v_a,
                             description: ""
v_aaa    = Quantity.create name: "Retinol (A1)",         domain: :diet, parent: v_aa,
                             description: ""
v_ab     = Quantity.create name: "Provitamin A",         domain: :diet, parent: v_a,
                             description: ""
v_aba    = Quantity.create name: "beta-Carotene",        domain: :diet, parent: v_ab,
                             description: ""
v_ac     = Quantity.create name: "Vitamin B",            domain: :diet, parent: v_a,
                             description: ""
v_aca    = Quantity.create name: "Thiamine (B1)",        domain: :diet, parent: v_ac,
                             description: ""
v_acb    = Quantity.create name: "Riboflavin (B2)",      domain: :diet, parent: v_ac,
                             description: "Vitamin G"
v_acc    = Quantity.create name: "Vitamin B3",           domain: :diet, parent: v_ac,
                             description: "Vitamin PP"
v_acca   = Quantity.create name: "Niacin",               domain: :diet, parent: v_acc,
                             description: "Nicotinic acid"
v_acd    = Quantity.create name: "Vitamin B5",           domain: :diet, parent: v_ac,
                             description: "Pantothenic acid"
v_ace    = Quantity.create name: "Vitamin B6",           domain: :diet, parent: v_ac,
                             description: ""
v_acf    = Quantity.create name: "Biotin (B7)",          domain: :diet, parent: v_ac,
                             description: "Vitamin H, also coenzyme R"
v_acg    = Quantity.create name: "Folate",               domain: :diet, parent: v_ac,
                             description: "Includes: folic acid, folacin and vitamin B9"
v_acga   = Quantity.create name: "Vitamin B9",           domain: :diet, parent: v_acg,
                             description: ""
v_ach    = Quantity.create name: "Cobalamin (B12)",      domain: :diet, parent: v_ac,
                             description: ""
v_ad     = Quantity.create name: "Vitamin C",            domain: :diet, parent: v_a,
                             description: ""
v_ae     = Quantity.create name: "Vitamin D",            domain: :diet, parent: v_a,
                             description: "Calciferol"
v_aea    = Quantity.create name: "Cholecalciferol (D3)", domain: :diet, parent: v_ae,
                             description: ""
v_af     = Quantity.create name: "Vitamin E",            domain: :diet, parent: v_a,
                             description: ""
v_ag     = Quantity.create name: "Vitamin K",            domain: :diet, parent: v_a,
                             description: ""

# -> Body composition
b_a      = Quantity.create name: "Body composition",     domain: :measurement, parent: nil,
                             description: ""
b_aa     = Quantity.create name: "Weight",               domain: :measurement, parent: b_a,
                             description: "Total weight"
b_aaa    = Quantity.create name: "Fat",                  domain: :measurement, parent: b_aa,
                             description: "Fat weight"
b_aab    = Quantity.create name: "Muscle",               domain: :measurement, parent: b_aa,
                             description: "Muscle weight"
b_ab     = Quantity.create name: "Composition",          domain: :measurement, parent: b_a,
                             description: ""
b_aba    = Quantity.create name: "% fat",                domain: :measurement, parent: b_ab,
                             description: "Fat as a % of total body weight"
b_abb    = Quantity.create name: "% muscle",             domain: :measurement, parent: b_ab,
                             description: "Muscle as a % of total body weight"
b_ac     = Quantity.create name: "RM",                   domain: :measurement, parent: b_a,
                             description: "Resting metabolism"
b_ad     = Quantity.create name: "VF",                   domain: :measurement, parent: b_a,
                             description: "Visceral fat"

# -> Target conditions
t_a  = Quantity.create name: "below", domain: :target, parent: nil,
                        description: "Upper bound"
t_b  = Quantity.create name: "above", domain: :target, parent: nil,
                        description: "Lower bound"
t_ba = Quantity.create name: "and below", domain: :target, parent: t_b,
                        description: "Range"
t_c  = Quantity.create name: "equal", domain: :target, parent: nil,
                        description: "Exact value"
t_ca = Quantity.create name: "with accuracy of", domain: :target, parent: t_c,
                        description: "Point range"

# Formulas go at the and to make sure dependencies exist
e_aa.create_formula  zero_nil: true, unit: u_b,
                       code: "4*Proteins + 9*Fats + 4*Carbs + 2*Fibre"
e_ab.create_formula  zero_nil: true, unit: u_c,
                       code: "100*Energy/RM.lastBefore(Meal.eaten_at||Meal.created_at)"
e_ac.create_formula  zero_nil: true, unit: u_b,
                       code: "4*Proteins"
e_aca.create_formula zero_nil: true, unit: u_c,
                       code: "100*proteins/RM.lastBefore(Meal.eaten_at||Meal.created_at)"
e_ad.create_formula  zero_nil: true, unit: u_b,
                       code: "4*Fats"
e_ada.create_formula zero_nil: true, unit: u_c,
                       code: "100*fats/RM.lastBefore(Meal.eaten_at||Meal.created_at)"
e_ae.create_formula  zero_nil: true, unit: u_b,
                       code: "4*Carbs"
e_aea.create_formula zero_nil: true, unit: u_c,
                       code: "100*carbs/RM.lastBefore(Meal.eaten_at||Meal.created_at)"

b_aaa.create_formula zero_nil: true, unit: u_ac,
                       code: "'% fat' * Weight"

t_a.create_formula  zero_nil: false, code: "value <= below"
t_b.create_formula  zero_nil: false, code: "value >= above"
t_ba.create_formula zero_nil: false, code: "(value >= above) && (value <= 'and below')"
t_c.create_formula  zero_nil: false, code: "value == equal"
t_ca.create_formula zero_nil: false, code: "(value >= (equal - 'with accuracy of')) && " \
                      "(value <= (equal + 'with accuracy of'))"

# Sources
s_a = Source.create name: "nutrition label",
                      description: "nutrition facts taken from package nutrition label"
