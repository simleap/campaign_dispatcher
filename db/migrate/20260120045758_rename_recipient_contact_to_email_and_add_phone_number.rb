class RenameRecipientContactToEmailAndAddPhoneNumber < ActiveRecord::Migration[7.2]
  def up
    remove_index :recipients, name: "index_recipients_on_campaign_id_and_contact", if_exists: true

    rename_column :recipients, :contact, :email
    change_column_null :recipients, :email, true

    add_column :recipients, :phone_number, :string

    add_index :recipients, %i[campaign_id email], unique: true
    add_index :recipients, %i[campaign_id phone_number], unique: true

    add_check_constraint(
      :recipients,
      "email IS NOT NULL OR phone_number IS NOT NULL",
      name: "recipients_email_or_phone_check"
    )
  end

  def down
    remove_check_constraint :recipients, name: "recipients_email_or_phone_check", if_exists: true

    remove_index :recipients, column: %i[campaign_id phone_number], if_exists: true
    remove_index :recipients, column: %i[campaign_id email], if_exists: true

    remove_column :recipients, :phone_number

    change_column_null :recipients, :email, false
    rename_column :recipients, :email, :contact

    add_index :recipients, %i[campaign_id contact], unique: true
  end
end
