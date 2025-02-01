


file_data = File.readlines("measurements.txt")
stations = {}
file_data.each do |line|
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

stations.each do |station, temps|
  min = temps.min
  max = temps.max
  mean = temps.sum / temps.length
  if !printed
    puts "#{station}=#{min}/#{mean}/#{max}"
    printed = true
  end
end