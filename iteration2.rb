require 'ruby-prof'
#require 'memory_profiler'
#require "get_process_mem"

#result = RubyProf::Profile.profile do
#report = MemoryProfiler.report do
#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"
  stations = {}
  file = File.foreach('measurements.txt') do |line|
    station, temp = line.split(';')
    stations[station] ||= {
      min: 0,
      max: 0,
      mean: 0,
      sum: 0,
      count: 0
    }
    float_temp = temp.to_f
    stations[station][:min] = float_temp if float_temp < stations[station][:min]
    stations[station][:max] = float_temp if float_temp > stations[station][:max]
    stations[station][:sum] += float_temp
    stations[station][:count] += 1
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
end
#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"

# File.open "iteration2-profile-stack.html", 'w+' do |file|
#   RubyProf::CallStackPrinter.new(result).print(file)
# end

#report.pretty_print

# $ time ruby iteration2.rb 
# Banjul=-23.3/25.99548007567204/82.1

# real	8m53.610s
# user	8m43.876s
# sys	0m5.931s

# $ ruby iteration2.rb
# MEMORY USAGE(MB): 18
# Banjul=-23.3/25.99548007567204/82.1
# MEMORY USAGE(MB): 10
