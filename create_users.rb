#!/usr/bin/env ruby

missing_users = [
  {name: 'Neeraj Ravindra', email: 'neeraj.r@samsung.com', primary_strength: 'Product', secondary_strength: 'Design'},
  {name: 'Subrat Pattanaik', email: 'subrat.p@samsung.com', primary_strength: 'Backend', secondary_strength: 'Full-stack'},
  {name: 'Akshat 8797', email: 'akshat8797@samsung.com', primary_strength: 'Backend', secondary_strength: 'DevOps'},
  {name: 'Sushan Suresh Sapaliga', email: 'sushan.sapaliga@samsung.com', primary_strength: 'Backend', secondary_strength: 'Integration test'}
]

missing_users.each do |user_data|
  begin
    user = User.create!(
      name: user_data[:name],
      email: user_data[:email],
      password: 'password123',
      password_confirmation: 'password123',
      primary_strength: user_data[:primary_strength],
      secondary_strength: user_data[:secondary_strength],
      role: 'team_member'
    )
    puts "Created user: #{user.name} (#{user.email})"
  rescue => e
    puts "Error creating user #{user_data[:name]}: #{e.message}"
  end
end