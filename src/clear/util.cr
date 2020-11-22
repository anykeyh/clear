# A set of method(s) useful for building Clear ORM.
module Clear::Util
  extend self

  # Equivalent to ruby's lambda with one parameter.
  # This method is useful combined with the macro system of Crystal.
  def lambda(u : U.class, v : V.class, &block : U -> V) forall U, V
    block
  end

  # Return a new hash which is union of two hash (some kind of deep merge)
  def hash_union(h1 : Hash(A, B), h2 : Hash(C, D)) : Hash(A | C, B | D) forall A, B, C, D
    o = Hash(A | C, B | D).new

    h1.each do |k, v|
      o[k] = v
    end

    h2.each do |k, v|
      case v
      when Hash
        if (v1 = o[k]).is_a?(Hash)
          o[k] = hash_union(v1, v)
        else
          o[k] = v
        end
      else
        o[k] = v
      end
    end

    o
  end

  # :nodoc:
  macro to_proc(*args, &block)
    -> ({{args.join(", ").id}}) { {{block.body}} }
  end
end
