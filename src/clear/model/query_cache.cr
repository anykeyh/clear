# This is a fire-and-forget cache
#
# This cache can be plugged on model instance (one cache for a set of models)
# ... (to explain and document)
class Clear::Model::QueryCache
  record CacheKey, relation_name : String, relation_value : Clear::SQL::Any, relation_model : String

  @cache : Hash(CacheKey, Pointer(Void)) = {} of CacheKey => Pointer(Void)
  @cache_activation : Set(String) = Set(String).new

  getter call : Int64 = 0_i64
  getter miss : Int64 = 0_i64
  getter hit : Int64 = 0_i64

  def fetch
    query
  end

  def active(relation_name)
    @cache_activation.add(relation_name)
  end

  def active?(relation_name)
    @cache_activation.includes?(relation_name)
  end

  # Try to hit the cache. If an array is found, it will be returned.
  # Otherwise, the block will be called and must return an array.
  def hit(relation_name, relation_value, klass : T.class) : Array(T) forall T
    miss = false

    o = @cache.fetch(CacheKey.new(relation_name, relation_value, T.name)) { miss = true }

    @call += 1
    miss ? (@miss += 1) : (@hit += 1)

    if miss
      [] of T
    else
      # See `set` below
      o.unsafe_as(Array(T))
    end
  end

  # Set the cached array for a specific key `{relation_name,relation_value}`
  def set(relation_name, relation_value, arr : Array(T)) forall T
    # NOTE: Following question #5289 on crystal-lang/crystal
    # I'm just storing the array as `Pointer(Void)`.
    # Thus to make happy the compiler and keep away garbage collecting.
    # After that, I'm going to cast back to the real array type Array(T) in `hit` method
    # to prevent array recopy on hit.
    @cache[CacheKey.new(relation_name, relation_value, T.name)] = arr.unsafe_as(Pointer(Void))
  end

  def with_cache(&block)
    yield
    clear
  end

  def clear
    @cache.clear
    @miss = 0_i64
    @hit = 0_i64
    @call = 0_i64
  end
end
