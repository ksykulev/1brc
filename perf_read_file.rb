require "benchmark/memory"

###
# 1g_measurements.txt has 100_000_000 lines
###

### get page size
#$ getconf PAGESIZE
#16384
###

# Ensures that OS can efficiently reading the file into memory
BUFFER = 16384

Benchmark.memory do |x|
  x.report("foreach") {
    File.foreach("1g_measurements.txt") do |line|
      line
    end
  }

  x.report("stream.read") {
    stream = File.new("1g_measurements.txt")

    until stream.eof?
      stream.read(BUFFER)
    end
  }

  x.compare!
end


# $ ruby perf_read_file.rb 
# Calculating -------------------------------------
#              foreach     4.874B memsize (     0.000  retained)
#                        100.000M objects (     0.000  retained)
#                         50.000  strings (     0.000  retained)
#          stream.read     1.383B memsize (     0.000  retained)
#                         84.206k objects (     0.000  retained)
#                         50.000  strings (     0.000  retained)

# Comparison:
#          stream.read: 1383034509 allocated
#              foreach: 4873514292 allocated - 3.52x more