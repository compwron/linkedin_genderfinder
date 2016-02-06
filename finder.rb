require "json"
require "csv"

names = []
file = "linkedin_connections_export_microsoft_outlook.csv"
CSV.foreach(file) do |row|
  names << row[1]
end

api = "https://api.genderize.io/?name="

name_results = File.open("results.txt", "w")
json_results = []
names.each {|n|
  unless n == "First Name"
    n = n.split(" ").first
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
json_scared = []
gs = json_results.map {|l|
  begin
    json = JSON.parse(l)
  rescue JSON::ParserError => e
    json_scared << l
    {}
  end
  {json["name"] => json["gender"]}
}.inject(&:merge)
p gs
female_count = gs.values.select{ |g| g == "female" }.count
male_count = gs.values.select{ |g| g == "male" }.count
other_names = gs.select { |k, v| !["female", "male"].include?(v) }

p json_scared
puts "female_count", female_count
puts "male_count", male_count
puts other_names
