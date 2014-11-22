require 'net/http'

20_000.times do |i|
  begin
    puts "done #{i}" if i % 1000 == 0
    result = Net::HTTP.get(URI.parse('http://127.0.0.1:8080/'))
  rescue => e
    puts "Failed on #{i}"
    raise e
  end
end