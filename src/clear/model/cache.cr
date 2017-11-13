class Clear::Model::Cache
  @@instance : Clear::Model::Cache?

  record CacheKey, relation_name : String, relation_value : Clear::SQL::Any, relation_model : String

  def self.instance : Clear::Model::Cache
    instance = @@instance

    if instance.nil?
      instance = @@instance = Clear::Model::Cache.new
    end

    instance
  end

  @cache : Hash(CacheKey, Array(Clear::Model)) = {} of CacheKey => Array(Clear::Model)

  getter call : Int64 = 0_i64
  getter miss : Int64 = 0_i64
  getter hit : Int64 = 0_i64

  # Try to hit the cache. If an array is found, it will be returned.
  # Otherwise, the block will be called and must return an array.
  def hit(relation_name, relation_value, klass : T.class, &block : -> Array(T)) forall T
    miss = false

    o = @cache.fetch(CacheKey.new(relation_name, relation_value, T.name)) { miss = true; yield }

    @call += 1
    miss ? (@miss += 1) : (@hit += 1)

    # See `set` below
    o.unsafe_as(Array(T))
  end

  # Set the cached array for a specific key `{relation_name,relation_value}`
  def set(relation_name, relation_value, arr : Array(T)) forall T
    # NOTE: Following question #5289 on crystal-lang/crystal
    # I'm just storing the array as Array(Clear::Model), even if it's not the case.
    # Thus to make happy the compiler and disable garbage collecting.
    # After that, I'm going to cast back to the real array type Array(T) in `hit` method
    # to prevent array recopy on hit.
    @cache[CacheKey.new(relation_name, relation_value, T.name)] = arr.unsafe_as(Array(Clear::Model))
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
