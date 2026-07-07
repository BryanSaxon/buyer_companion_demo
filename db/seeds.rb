# Idempotent seed for the Grand Rapids demo.
# Creates the Harrison family lead and pre-seeds their design session
# in the post-design (complete) state so the demo starts at the
# "design done, construction underway" moment.

lead = Lead.find_or_initialize_by(email: "michael.harrison@gmail.com")
lead.assign_attributes(
  first_name: "Michael",
  last_name:  "Harrison",
  company:    "Signature Homes"
)
lead.save!

# Destroy any existing session + messages so the seed is idempotent
lead.chat_messages.delete_all
lead.design_session&.destroy

DemoSeeder.seed_harrison_session(lead)

puts "Seeded Harrison demo: lead ##{lead.id} with complete design session"
