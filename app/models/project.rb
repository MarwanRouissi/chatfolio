require 'json'

class Project < ApplicationRecord
  def self.get_stack_icon(techno)
    file_path = Rails.root.join('lib', 'assets', 'stack_logo.json')
    file_content = File.read(file_path)
    stack_logo_data = JSON.parse(file_content)

    stack_logo_data[techno]
  end
end
