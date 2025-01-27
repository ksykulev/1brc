require 'ruby-prof'

result = RubyProf::Profile.profile do
  stations = {}
  file = File.foreach('measurements.txt') do |line|
    station, temp = line.split(';')
    stations[station] ||= []
    stations[station] << temp.to_f
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
end

File.open "iteration1-profile-stack.html", 'w+' do |file|
  RubyProf::CallStackPrinter.new(result).print(file)
end


# $ time ruby iteration1.rb 
# Banjul=-23.3/25.995480075670848/82.1

# real	6m25.861s
# user	6m14.734s
# sys	0m9.596s
