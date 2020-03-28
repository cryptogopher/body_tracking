class Column < ActiveRecord::Base
  belongs_to :column_view, polymorphic: true
  belongs_to :quantity
end
