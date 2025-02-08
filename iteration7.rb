require 'concurrent-ruby'
#require 'ruby-prof'
#require "get_process_mem"

#result = RubyProf::Profile.profile do
#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"
parser_executor = Concurrent::ThreadPoolExecutor.new(
  min_threads: 10,
  max_threads: 10,
  max_queue: 0,
  fallback_policy: :caller_runs
)

stations = {}
lines = []
file = File.foreach('measurements.txt').with_index do |line, line_number|
  lines << line
  if line_number != 0 && line_number % 1000 == 0
    parser_executor.post(lines) do |lines|
      lines.each do |l|
        station, temp = l.split(';')
        stations[station] ||= []
        stations[station] << temp.to_f
      end
    end
    lines = []
  end
end

parser_executor.shutdown
parser_executor.wait_for_termination

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

# File.open "iteration7-profile-stack.html", 'w+' do |file|
#  RubyProf::CallStackPrinter.new(result).print(file)
# end
#mb = GetProcessMem.new.mb
#puts "MEMORY USAGE(MB): #{ mb.round }"


# $ time ruby iteration7.rb 
# Banjul=-23.3/25.995475114243824/82.1

# real	7m14.603s
# user	6m59.213s
# sys	0m14.024s

# $ ruby iteration7.rb 
# MEMORY USAGE(MB): 18
# Banjul=-23.3/25.995475114243824/82.1
# MEMORY USAGE(MB): 8337