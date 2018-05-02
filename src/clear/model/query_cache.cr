# This is a fire-and-forget cache
#
# This cache can be plugged on model instance (one cache for a set of models)
# ... (TODO: explain and document)
class Clear::Model::QueryCache
  record CacheKey, relation_name : String, relation_value : Clear::SQL::Any, relation_model : String

  @cache : Hash(CacheKey, Pointer(Void)) = {} of CacheKey => Pointer(Void)
  @cache_activation : Set(String) = Set(String).new

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
    @cache.fetch CacheKey.new(relation_name, relation_value, T.name) do
      [] of T
    end.unsafe_as(Array(T))
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
    @cache_activation.clear
  end
end
