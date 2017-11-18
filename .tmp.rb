ME = "anykeyh"
OTHER = "anykeyh"
current_owner = `id -u #{ME}`.to_i
owner_to_resolve = `id -u #{OTHER}`.to_i

Dir["/**/*"].each do |file|
  puts file
  if File.stat(file).uid == owner_to_resolve
    puts "Resolve chown #{ME} #{file}"
  end
end
