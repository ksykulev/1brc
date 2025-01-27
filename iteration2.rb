require 'ruby-prof'

result = RubyProf::Profile.profile do
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
  stations[station][:mean] = stations[station][:sum] / stations[station][:count]
  end

  printed = false

  stations.each do |station, measurements|
    if !printed
      puts "#{station}=#{measurements[:min]}/#{measurements[:mean]}/#{measurements[:max]}"
      printed = true
    end
  end 
end

File.open "iteration2-profile-stack.html", 'w+' do |file|
  RubyProf::CallStackPrinter.new(result).print(file)
end

# $ time ruby iteration2.rb 
# Banjul=-23.3/25.99548007567204/82.1

# real	10m27.363s
# user	10m22.129s
# sys	0m4.829s
