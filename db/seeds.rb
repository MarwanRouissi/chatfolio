# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'json'

# Load the JSON data from the file
file_path = Rails.root.join('lib', 'assets', 'my_projects.json')
file_content = File.read(file_path)
projects_data = JSON.parse(file_content)

puts "Deleting existing projects..."
Project.destroy_all

puts "Creating projects..."
projects_data['projects'].each do |project_data|
  Project.find_or_create_by!(
    name: project_data['name'],
    description: project_data['description'],
    github_url: project_data['github_url'],
    technologies: project_data['technologies'],
    features: project_data['features'],
    challenges: project_data['challenges'],
    potential_improvements: project_data['potential_improvements']
  )
end

puts "Projects created successfully! Total: #{Project.count} projects."
