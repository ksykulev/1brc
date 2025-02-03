require 'concurrent-ruby'
require 'ruby-prof'

#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"

#result = RubyProf::Profile.profile do
  stations = {}
  file = File.foreach('measurements.txt') do |line|
    station, temp = line.split(';')
    stations[station] ||= []
    stations[station] << temp.to_f
  end

  executor = Concurrent::ThreadPoolExecutor.new(
    min_threads: 5,
    max_threads: 10,
    max_queue: 0,
    fallback_policy: :caller_runs
  )
  # :caller_runs - when the task queue is full, the 
  # task will be executed in the thread that submitted the task, 
  # rather than being queued or rejected

  stations.each_with_index do |(station, temps), i|
    executor.post(station, temps, i) do |s, t, i|
      min = t.min
      max = t.max
      mean = t.sum / t.length
      string = "#{s}=#{min}/#{mean}/#{max}"

      if i==0
        puts string
      end
    end
  end

  executor.shutdown
  executor.wait_for_termination
#end

#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"

#File.open "iteration5-profile-stack.html", 'w+' do |file|
#  RubyProf::CallStackPrinter.new(result).print(file)
#end


# $ time ruby iteration5.rb 
# Banjul=-23.3/25.995480075670848/82.1

# real	6m33.778s
# user	6m24.528s
# sys	0m8.197s


# $ ruby iteration5.rb 
# MEMORY USAGE(MB): 18
# Banjul=-23.3/25.995480075670848/82.1
# MEMORY USAGE(MB): 8087

