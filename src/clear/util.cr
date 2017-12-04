# A set of methods useful for building Clear ORM.
module Clear::Util
  extend self

  # Equivalent to ruby's lambda with one parameter.
  def func(u : U.class, v : V.class, &block : U -> V) forall U, V
    block
  end
end
