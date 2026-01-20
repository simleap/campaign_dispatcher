require "rails_helper"

RSpec.describe "Campaign dispatch realtime updates", type: :system, js: true do
  include Turbo::SystemTestHelper

  it "creates a campaign with nested recipients and updates live during dispatch" do
    visit root_path
    click_link "New campaign"

    fill_in "Title", with: "Realtime campaign"

    rows = all("[data-nested-form-target='row']")
    expect(rows.size).to eq(1)

    within rows[0] do
      fill_in "Name", with: "Alice"
      fill_in "Email", with: "alice@example.com"
    end

    click_button "Add recipient"
    click_button "Add recipient"
    expect(page).to have_selector("[data-nested-form-target='row']", count: 3)

    rows = all("[data-nested-form-target='row']")

    within rows[1] do
      fill_in "Name", with: "Bob"
      fill_in "Email", with: "bob@example.com"
    end

    within rows[2] do
      fill_in "Name", with: "Charlie"
      fill_in "Phone number", with: "+15551234567"
    end

    within rows[1] do
      click_button "Remove"
    end

    expect(page).to have_selector("[data-nested-form-target='row']", count: 2)

    click_button "Create Campaign"
    expect(page).to have_text("Campaign created.")

    expect(page).to have_text("Alice")
    expect(page).to have_text("alice@example.com")
    expect(page).to have_text("Charlie")
    expect(page).to have_text("+15551234567")
    expect(page).not_to have_text("Bob")

    expect(page).to have_text("Queued: 2")
    click_button "Dispatch Campaign"
    expect(page).to have_text("Processing…")

    connect_turbo_cable_stream_sources
    DispatchCampaignJob.drain

    expect(page).to have_text("Completed")
    expect(page).to have_text("Queued: 0")
    expect(page).to have_text("Sent: 2")
    expect(page).to have_text("Failed: 0")

    within find("tr", text: "alice@example.com") do
      expect(page).to have_text("Sent")
    end

    within find("tr", text: "+15551234567") do
      expect(page).to have_text("Sent")
    end
  end
end
