require 'ruby-prof'
# require "get_process_mem"

#result = RubyProf::Profile.profile do
# mb = GetProcessMem.new.mb
# puts "MEMORY USAGE(MB): #{ mb.round }"
stations = Hash.new(capacity: 10_000)
BUFFER = 16384
stream = File.new("measurements.txt")

remainder = ''
until stream.eof?
  lines_str = stream.read(BUFFER)
  if remainder.length > 0
    lines_str = remainder + lines_str
    remainder = ''
  end
  last_newline = lines_str.rindex("\n")

  if last_newline
    part1 = lines_str[0..last_newline]
    remainder = lines_str[(last_newline + 1)..-1]
  else
    part1 = lines_str
  end

  list = part1.split("\n").map do |line|
    station, temp = line.split(';')
      if !stations.has_key?(station) 
        stations[station] = {
          min: 0,
          max: 0,
          sum: 0,
          count: 0
        }
      end
      float_temp = temp.to_f
      stations[station][:min] = float_temp if float_temp < stations[station][:min]
      stations[station][:max] = float_temp if float_temp > stations[station][:max]
      stations[station][:sum] += float_temp
      stations[station][:count] += 1    
  end
end

printed = false

stations.each do |station, measurements|
  mean = measurements[:sum] / measurements[:count]
  string = "#{station}=#{measurements[:min]}/#{mean}/#{measurements[:max]}"
  if !printed
    puts string
    printed = true
  end
end 
#end
# mb = GetProcessMem.new.mb
# puts "MEMORY USAGE(MB): #{ mb.round }"

# File.open "iteration10-profile-stack.html", 'w+' do |file|
#  RubyProf::CallStackPrinter.new(result).print(file)
# end