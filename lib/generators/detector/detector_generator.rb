class DetectorGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_detector_file
    parts = file_name.split(/\s+/)
    service = parts.shift
    detector_name = parts.join('_')

    contents = File.read(File.expand_path("templates/detector.txt", __dir__))
      .gsub("{service}", service)
      .gsub("{detector_name}", detector_name)
      .gsub("{detector_class_name}", detector_name.camelize)
    create_file("lib/detector/#{service}/#{detector_name}.rb", contents)
  end

  def create_detector_test_file
    parts = file_name.split(/\s+/)
    service = parts.shift
    detector_name = parts.join('_')

    contents = File.read(File.expand_path("templates/detector-test.txt", __dir__))
      .gsub("{service}", service)
      .gsub("{detector_name}", detector_name)
      .gsub("{detector_class_name}", detector_name.camelize)
    create_file("test/lib/detector/#{service}/#{detector_name}_test.rb", contents)
  end
end
