require 'json'

class Project < ApplicationRecord
  def self.get_stack_icon(techno)
    # Load the JSON data from the file
    file_path = Rails.root.join('lib', 'assets', 'stack_logo.json')
    file_content = File.read(file_path)
    stack_logo_data = JSON.parse(file_content)

    # Debugging statement
    puts "Looking for: #{techno}"
    puts "Data: #{stack_logo_data.inspect}"
    stack_logo_data[techno]
  end
end
