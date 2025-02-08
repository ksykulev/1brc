require 'thread'
value = ['hello world']

t = Thread.new do
  sleep 1
  value.each do |v|
    puts v
  end
end

value = ['good bye world']

t.join
