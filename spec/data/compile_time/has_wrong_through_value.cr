require "../../../src/clear"

class MyModel
  include Clear::Model

  has_one model_in_between : ModelInBetween

  has_many has_many_through_models : HasManyThroughModel, through: :model_in_between
end

class ModelInBetween1
  include Clear::Model
  belongs_to my_model : MyModel
end

class HasManyThroughModel
  include Clear::Model

  has_one model_in_between : ModelInBetween
  has_many my_models : MyModel, through: :model_in_betweens # < Made mistake adding a `s` to the through value
end
