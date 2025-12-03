class CreateRisks < ActiveRecord::Migration[8.1]
  def change
    create_table :risks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :scope_item, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :likelihood
      t.string :impact
      t.string :status, default: "identified"
      t.text :mitigation_plan
      t.timestamps
    end
  end
end
