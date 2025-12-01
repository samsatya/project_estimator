# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create sample users for login
users_data = [
  {
    name: "John Doe",
    email: "john@example.com",
    password: "password123",
    primary_strength: "Backend",
    secondary_strength: "Full-stack",
    capacity: 40
  },
  {
    name: "Jane Smith",
    email: "jane@example.com",
    password: "password123",
    primary_strength: "Frontend",
    secondary_strength: "Design",
    capacity: 40
  },
  {
    name: "Bob Johnson",
    email: "bob@example.com",
    password: "password123",
    primary_strength: "Full-stack",
    secondary_strength: "Backend",
    capacity: 35
  },
  {
    name: "Alice Williams",
    email: "alice@example.com",
    password: "password123",
    primary_strength: "QA",
    secondary_strength: "Frontend",
    capacity: 40
  }
]

users_data.each do |user_data|
  user = User.find_or_initialize_by(email: user_data[:email])
  user.assign_attributes(user_data)
  if user.new_record? || user.changed?
    user.save!
    puts "Created/Updated user: #{user.email}"
  else
    puts "User already exists: #{user.email}"
  end
end

puts "\n✅ Seed data created successfully!"
puts "\nYou can now login with any of these accounts:"
users_data.each do |user_data|
  puts "  Email: #{user_data[:email]} | Password: #{user_data[:password]}"
end
