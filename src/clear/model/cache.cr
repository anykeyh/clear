class Clear::Model::Cache
  @@instance : Clear::Model::Cache?

  record CacheKey, relation_name : String, relation_value : Clear::SQL::Any

  def self.instance : Clear::Model::Cache
    instance = @@instance

    if instance.nil?
      instance = @@instance = Clear::Model::Cache.new
    end

    instance
  end

  @cache : Hash(CacheKey, Array(Clear::Model)) = {} of CacheKey => Array(Clear::Model)

  def hit(relation_name, relation_value, klass : T.class, &block) forall T
    puts "Hit cache #{relation_name}=#{relation_value}"
    o = @cache.fetch(CacheKey.new(relation_name, relation_value)) { yield }

    # One of the limitations of crystal is
    # array of Model cannot be casted to array of subclass of Model :-(.
    o.map(&.as(T))
  end

  def add(relation_name, relation_value, models : Array(T)) forall T
    puts "Add to cache #{relation_name}=#{relation_value}"
    arr = models.map(&.as(Clear::Model))
    @cache[CacheKey.new(relation_name, relation_value)] = arr
  end

  def with_cache(&block)
    yield
    clear
  end

  def clear
    @cache.clear
  end
end
