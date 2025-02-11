require 'concurrent-ruby'
require 'ruby-prof'
#require "get_process_mem"

#result = RubyProf::Profile.profile do
# mb = GetProcessMem.new.mb
# puts "MEMORY USAGE(MB): #{ mb.round }"
BUFFER = 16384
stream = File.new("measurements.txt")

$parser_executor = Concurrent::ThreadPoolExecutor.new(
  min_threads: 10,
  max_threads: 10,
  max_queue: 0,
  fallback_policy: :caller_runs
)

$aggregate_executor = Concurrent::ThreadPoolExecutor.new(
  min_threads: 10,
  max_threads: 10,
  max_queue: 0,
  fallback_policy: :caller_runs
)

$mutexes = Concurrent::Hash.new { |hash, key| hash[key] = Mutex.new }
$stations = {}

def process_chunk(chunk)
  list = chunk.split("\n").map do |line|
    station, temp = line.split(';')
    [station, temp.to_f]
  end

  $aggregate_executor.post(list) { |stations_list| process_stations(stations_list) }
rescue => e
  binding.pry
end

def process_stations(stations_list)
  stations_list.each do |tuple|
    station, float_temp = tuple
    $mutexes[station].synchronize do
      $stations[station] ||= {
        min: Float::INFINITY,
        max: -Float::INFINITY,
        sum: 0,
        count: 0
      }

      $stations[station][:min] = float_temp if float_temp < $stations[station][:min]
      $stations[station][:max] = float_temp if float_temp > $stations[station][:max]
      $stations[station][:sum] += float_temp
      $stations[station][:count] += 1
    end
  end
  rescue => e
    binding.pry
end

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
    binding.pry
    part1 = lines_str
  end

  $parser_executor.post(part1) { |chunk| process_chunk(chunk) }
end

$parser_executor.shutdown
$parser_executor.wait_for_termination

$aggregate_executor.shutdown
$aggregate_executor.wait_for_termination

printed = false
$stations.each do |station, measurements|
  mean = measurements[:sum] / measurements[:count].to_f
  string = "#{station}=#{measurements[:min]}/#{mean}/#{measurements[:max]}"
  if !printed
    puts string
    printed = true
  end
end
#end
# mb = GetProcessMem.new.mb
# puts "MEMORY USAGE(MB): #{ mb.round }"


# $ time ruby iteration9.rb 
# Banjul=-23.3/25.99548007567204/82.1

# real	11m41.994s
# user	11m29.945s
# sys	0m12.541s


# $ ruby iteration9.rb 
# MEMORY USAGE(MB): 17
# Banjul=-23.3/25.99548007567204/82.1
# MEMORY USAGE(MB): 18

# File.open "iteration9-profile-stack.html", 'w+' do |file|
#  RubyProf::CallStackPrinter.new(result).print(file)
# end