class CreateCampaigns < ActiveRecord::Migration[7.2]
  def change
    create_table :campaigns do |t|
      t.string :title, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_check_constraint(
      :campaigns,
      "status IN ('pending', 'processing', 'completed')",
      name: "campaigns_status_check"
    )
  end
end
