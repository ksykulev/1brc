require 'thread'
value = ['hello world']
 
t = Thread.new(value) do |item|
  sleep 1
  item.each do |v|
    puts v
  end
end
 
value = ['good bye world']
 
t.join
