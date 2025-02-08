require 'concurrent-ruby'

executor = Concurrent::ThreadPoolExecutor.new(
  min_threads: 10,
  max_threads: 10,
  max_queue: 0,
  fallback_policy: :caller_runs
)

work = ['hello world']
puts work.object_id
executor.post(work) do |item|
  sleep 1
  puts item.object_id
  item.each do |v|
    puts v
  end
end

work = []
executor.shutdown
executor.wait_for_termination
