=begin
Cache system

user.with_posts{ |c| c.published.with_category }.each do |user|
  #...
end

# => with_posts
#   => save cache in collection
#   => Cache will be given to all user models
#     => On query on the has_many field, cache will be triggered
#       => save cache in collection
#       => Repeat...

=end