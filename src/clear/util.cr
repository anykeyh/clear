# A set of method(s) useful for building Clear ORM.
module Clear::Util
  extend self

  # Equivalent to ruby's lambda with one parameter.
  # This method is useful combined with the macro system of Crystal.
  def lambda(u : U.class, v : V.class, &block : U -> V) forall U, V
    block
  end
end
