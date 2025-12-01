class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.date :start_date
      t.date :target_date
      t.string :status, default: "planning"
      t.decimal :pr_review_time_percentage, default: 0.15, precision: 5, scale: 2
      t.decimal :product_testing_time_percentage, default: 0.20, precision: 5, scale: 2
      t.decimal :business_testing_time_percentage, default: 0.15, precision: 5, scale: 2
      t.decimal :points_to_hours_conversion, default: 8.0, precision: 5, scale: 2

      t.timestamps
    end
  end
end
