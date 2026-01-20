class CreateRecipients < ActiveRecord::Migration[7.2]
  def change
    create_table :recipients do |t|
      t.references :campaign, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :contact, null: false
      t.string :status, null: false, default: "queued"
      t.datetime :sent_at
      t.string :error_message

      t.timestamps

      t.index [ :campaign_id, :status ]
      t.index [ :campaign_id, :contact ], unique: true
    end

    add_check_constraint(
      :recipients,
      "status IN ('queued', 'sent', 'failed')",
      name: "recipients_status_check"
    )
  end
end
