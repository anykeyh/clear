require "../../../src/clear"

class MyModel
  include Clear::Model
  has_one model_in_between : ModelInBetween
  has_many has_many_through_models : HasManyThroughModel, through: :model_in_between
end

class ModelInBetween
  include Clear::Model
  belongs_to my_model : MyModel
  belongs_to model_in_between_2 : ModelInBetween2
end

class ModelInBetween2
  include Clear::Model
  # has_many model_in_between : ModelInBetween
  # has_many my_models : MyModel, through: :model_in_between
  belongs_to has_many_through_model : HasManyThroughModel
end

class HasManyThroughModel
  include Clear::Model

  has_one model_in_between2 : ModelInBetween2
  has_many my_models : MyModel, through: :model_in_between2
end
