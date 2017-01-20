class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :domain
      t.text :content
      t.string :author_name
      t.string :publisher_name
      t.text :keywords
      t.text :about_content
      t.text :sources

      t.timestamps null: false
    end
  end
end
