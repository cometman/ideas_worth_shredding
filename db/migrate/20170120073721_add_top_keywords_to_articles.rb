class AddTopKeywordsToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :top_keywords, :text
  end
end
