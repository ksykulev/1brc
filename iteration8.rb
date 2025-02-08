require 'concurrent-ruby'
#require 'ruby-prof'
#require "get_process_mem"

# result = RubyProf::Profile.profile do
# mb = GetProcessMem.new.mb
# puts "MEMORY USAGE(MB): #{ mb.round }"
parser_executor = Concurrent::ThreadPoolExecutor.new(
  min_threads: 10,
  max_threads: 10,
  max_queue: 0,
  fallback_policy: :caller_runs
)

aggregate_executor = Concurrent::ThreadPoolExecutor.new(
  min_threads: 10,
  max_threads: 10,
  max_queue: 0,
  fallback_policy: :caller_runs
)

mutexes = Concurrent::Hash.new { |hash, key| hash[key] = Mutex.new }
stations = {} #Concurrent::Hash.new
lines = []

def process(tuple, mutexes, stations)
  stationstr, tempstr = tuple
  float_temp = tempstr.to_f
  mutexes[stationstr].synchronize do
    stations[stationstr][:min] = float_temp if float_temp < stations[stationstr][:min]
    stations[stationstr][:max] = float_temp if float_temp > stations[stationstr][:max]
    stations[stationstr][:sum] += float_temp
    stations[stationstr][:count] += 1
    #stations[stationstr][:sum].update { |value| value + float_temp }
    #stations[stationstr][:count].increment
  end
end

file = File.foreach('measurements.txt').with_index do |line, line_number|
  lines << line
  if line_number != 0 && line_number % 1000 == 0
    parser_executor.post(lines.dup) do |lines_array|
      stations_array = []
      lines_array.each_with_index do |l, ln|
        station, temp = l.split(';')
        # stations[station] ||= Concurrent::Hash.new.tap do |hash|
        #   hash[:min] = Float::INFINITY
        #   hash[:max] = -Float::INFINITY
        #   hash[:sum] = Concurrent::AtomicFixnum.new(0)
        #   hash[:count] = Concurrent::AtomicFixnum.new(0)
        # end
        stations[station] ||= {
          min: 0,
          max: 0,
          sum: 0,
          count: 0
        }
        stations_array << [station, temp]

        if(ln != 0 && ln % 500 == 0)
          aggregate_executor.post(stations_array) do |ss|
            ss.each do |tuple|
              process(tuple, mutexes, stations)
            end
          end
          stations_array = []
        end
      end
      # process the remaining stations
      if stations_array.any?
        aggregate_executor.post(stations_array) do |ss|
          ss.each do |tuple|
            process(tuple, mutexes, stations)
          end
        end
      end
    end

    lines = []
  end
end

parser_executor.shutdown
parser_executor.wait_for_termination

aggregate_executor.shutdown
aggregate_executor.wait_for_termination

printed = false
stations.each do |station, measurements|
  #mean = measurements[:sum].value / measurements[:count].value.to_f
  mean = measurements[:sum] / measurements[:count].to_f
  string = "#{station}=#{measurements[:min]}/#{mean}/#{measurements[:max]}"
  if !printed
    puts string
    printed = true
  end
end
#end

# File.open "iteration8-profile-stack.html", 'w+' do |file|
#  RubyProf::CallStackPrinter.new(result).print(file)
# end
# mb = GetProcessMem.new.mb
# puts "MEMORY USAGE(MB): #{ mb.round }"


# $ time ruby iteration8.rb 
# Banjul=-23.3/25.995475114245018/82.1

# real	13m48.698s
# user	13m31.141s
# sys	0m17.545s

# $ ruby iteration8.rb 
# MEMORY USAGE(MB): 18
# Banjul=-23.3/25.995475114245018/82.1
# MEMORY USAGE(MB): 17

# with all concurrency primatives on
# (more on why this doesn't _really_ matter in MRI)
# time ruby iteration8.rb 
# Banjul=-23.3/25.995475114245018/82.1

# real	18m38.702s
# user	18m20.451s
# sys	0m18.779s
