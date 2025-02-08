require 'concurrent-ruby'

executor = Concurrent::ThreadPoolExecutor.new(
  min_threads: 10,
  max_threads: 10,
  max_queue: 0,
  fallback_policy: :caller_runs
)

work = ['hello world']
puts "work.object_id:#{work.object_id}"
puts "1.work[0].object_id:#{work[0].object_id}"
executor.post(work) do |item|
  sleep 1
  puts "item.object_id:#{item.object_id}"
  puts "item[0].object_id:#{item[0].object_id}"
  puts item[0]
end

work[0] = 'new'
puts "3.work[0].object_id:#{work[0].object_id}"
executor.shutdown
executor.wait_for_termination
