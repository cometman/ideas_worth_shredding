class AddLinksToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :links, :text
  end
end
