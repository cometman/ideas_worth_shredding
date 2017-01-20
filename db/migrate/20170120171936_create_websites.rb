class CreateWebsites < ActiveRecord::Migration
  def change
    create_table :websites do |t|
      t.string :domain
      t.string :tag

      t.timestamps null: false
    end
  end
end
