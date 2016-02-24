require "json"
require "csv"
require "pry"

names = []
file = "linkedin_connections_export_microsoft_outlook.csv"
CSV.foreach(file) do |row|
  names << row[1]
end

api = "https://api.genderize.io/?name="

name_results = File.open("results.txt", "a+")
names_in_file = name_results.readlines.map {|l| JSON.parse(l)["name"]}
json_results = []
names.each {|n|
  unless n == "First Name"
    n = n.split(" ").first
    if names_in_file.include?(n)
      next
    end
    res = `curl --silent #{api}#{n}`
    json_results << res # write to file because the API is slow and we don't want to have to do this twice.
    name_results.puts res
    if JSON.parse(res)["error"] == "Request limit reached"
      puts "Sorry, gotta stop for a bit. #{res}"
      exit
    end
  end
}
name_results.close

json_results = File.readlines("results.txt")
gs = json_results.map {|l|
  json = JSON.parse(l)
  {json["name"] => json["gender"]}
}.inject(&:merge)

female_count = gs.values.select{ |g| g == "female" }.count
male_count = gs.values.select{ |g| g == "male" }.count
other_names = gs.select { |k, v| !["female", "male"].include?(v) }

puts "female_count", female_count
puts "male_count", male_count
puts "genderize doesn't know", other_names.count

