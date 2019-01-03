# The Clear::Model::QueryCache
# is a __fire-and-forget__ cache used when caching associations and preventing N+1 queries anti-pattern.
#
# This is not a global cache: One cache instance exists per collection, and the cache
# disappear at the same time the Collection is unreferenced.
#
# Each cache can references multiples relations at the same time.
# This cache use an underlying hash to access to the references keys.
class Clear::Model::QueryCache

  # :nodoc:
  record CacheKey, relation_name : String, relation_value : Clear::SQL::Any, relation_model : String

  # Store the associations through a Hash. For performance reaons, the hash is storing the array of models
  # as `Pointer(Void)` (while being underlying an Array(T)). This is a current limitation of Crystal, where
  # you cannot store nor cast safely an `Array(Child)` in a `Array(Parent)`
  # reference (while Child inheriting from Parent).
  @cache : Hash(CacheKey, Pointer(Void)) = {} of CacheKey => Pointer(Void)

  # References the current cached relations.
  @cache_activation : Set(String) = Set(String).new

  def fetch
    query
  end

  # Tell this cache than we active the cache over a specific relation name.
  # Returns `self`
  def active(relation_name)
    @cache_activation.add(relation_name)

    self
  end

  # Check whether the cache is active on a certain association.
  # Returns `true` if `relation_name` is flagged as encached, or `false` otherwise.
  def active?(relation_name)
    @cache_activation.includes?(relation_name)
  end

  # Try to hit the cache. If an array is found, it will be returned.
  # Otherwise, empty array is returned.
  #
  # This methods do not check if a relation flagged as is actively cached or not. Therefore, hitting a non-cached
  # relation will return always an empty-array.
  def hit(relation_name, relation_value, klass : T.class) : Array(T) forall T
    @cache.fetch CacheKey.new(relation_name, relation_value, T.name) do
      [] of T
    end.unsafe_as(Array(T))
  end

  # Set the cached array for a specific key `{relation_name,relation_value}`
  def set(relation_name, relation_value, arr : Array(T)) forall T
    # We store the array as `Pointer(Void)`.
    # Thus to make happy the compiler and keep away garbage collecting.
    # After that, I'm going to cast back to the real array type Array(T) in `hit` method
    # to prevent array recopy on hit.
    #
    # See: https://github.com/crystal-lang/crystal/issues/5289
    @cache[CacheKey.new(relation_name, relation_value, T.name)] = arr.unsafe_as(Pointer(Void))
  end

  # Perform some operations with the cache then eventually clear the cache.
  def with_cache(&block)
    begin
      yield
    ensure
      clear
    end
  end

  # Empty the cache and flag all relations has unactive
  def clear
    @cache.clear
    @cache_activation.clear
  end
end
