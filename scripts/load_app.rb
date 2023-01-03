Dir["./config/initializers/**.rb"].each do |it|
  require_relative "../#{it}"
end

Dir["./lib/**/*.rb"].each do |it|
  require_relative "../#{it}"
end
