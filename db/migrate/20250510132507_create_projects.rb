class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :name
      t.string :description
      t.string :github_url
      t.text :technologies, array: true
      t.text :features, array: true
      t.text :challenges, array: true
      t.text :potential_improvements, array: true

      t.timestamps
    end
  end
end
