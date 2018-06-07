# This is a "fire-and-forget" cache used to cache over associations to
# prevent N+1 queries
class Clear::Model::QueryCache
  # :nodoc:
  record CacheKey, relation_name : String, relation_value : Clear::SQL::Any, relation_model : String

  @cache : Hash(CacheKey, Pointer(Void)) = {} of CacheKey => Pointer(Void)
  @cache_activation : Set(String) = Set(String).new

  def fetch
    query
  end

  # Flag the caching as active on a certain model.
  def active(relation_name)
    @cache_activation.add(relation_name)
  end

  # Check whether the cache is active on a certain association.
  def active?(relation_name)
    @cache_activation.includes?(relation_name)
  end

  # Try to hit the cache. If an array is found, it will be returned.
  # Otherwise, empty array is returned.
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
