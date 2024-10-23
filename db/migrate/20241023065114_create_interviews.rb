class CreateInterviews < ActiveRecord::Migration[7.2]
  def change
    create_table :interviews do |t|
      t.string :user_name
      t.text :summary

      t.timestamps
    end
  end
end
