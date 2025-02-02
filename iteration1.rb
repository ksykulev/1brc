require 'ruby-prof'
#require "get_process_mem"

#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"
#result = RubyProf::Profile.profile do
  stations = {}
  file = File.foreach('measurements.txt') do |line|
    station, temp = line.split(';')
    stations[station] ||= []
    stations[station] << temp.to_f
  end

  printed = false

  stations.each do |station, temps|
    min = temps.min
    max = temps.max
    mean = temps.sum / temps.length
    string = "#{station}=#{min}/#{mean}/#{max}"
    if !printed
      puts string
      printed = true
    end
  end
#end
#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"

# File.open "iteration1-profile-stack.html", 'w+' do |file|
#   RubyProf::CallStackPrinter.new(result).print(file)
# end

# $ time ruby iteration1.rb 
# Banjul=-23.3/25.995480075670848/82.1

# real	6m25.861s
# user	6m14.734s
# sys	0m9.596s


# $ ruby iteration1.rb
# MEMORY USAGE(MB): 17
# Banjul=-23.3/25.995480075670848/82.1
# MEMORY USAGE(MB): 8437
