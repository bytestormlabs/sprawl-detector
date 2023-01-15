namespace :bytestorm do
  desc "Scans the detector directory and generates a manifest of them"
  task build_manifest: :environment do
    detector_path = File.expand_path("lib/detector", Dir.pwd)
    Dir.glob("#{detector_path}/**/*.rb").each do |file|
      path = file[(Dir.pwd.length + "/lib/".length)...-3]
      puts "require \"#{path}\"" unless path.include? "support"
    end
    puts ""

    detectors = Dir.glob("#{detector_path}/**/*.rb").map do |file|
      content = File.read(file)
      result = nil
      if /class (.*)/ =~ content
        result = "#{$1}.new"
      end
      result
    end

    detectors.delete("RequestBuilder.new")

    puts detectors.join(", \n")
  end
end
