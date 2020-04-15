class Exposure < ActiveRecord::Base
  belongs_to :view, polymorphic: true
  belongs_to :quantity
end
