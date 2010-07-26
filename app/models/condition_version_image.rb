class ConditionVersionImage < ActiveRecord::Base
  belongs_to :condition_version
  belongs_to :condition_image
end
