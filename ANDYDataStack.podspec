Pod::Spec.new do |s|
  s.name = "ANDYDataStack"
  s.version = "2.0"
  s.summary = "Core Data stack set up boilerplate."
  s.description = <<-DESC
                   * Feeling tired of having Core Data boilerplate in your AppDelegate?
                   * No more.
                   DESC
  s.homepage = "https://github.com/NSElvis/ANDYDataStack"
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.author = { "Elvis Nunez" => "elvisnunez@me.com" }
  s.social_media_url = "http://twitter.com/NSElvis"
  s.platform = :ios, '5.0'
  s.source = {
    :git => 'https://github.com/NSElvis/ANDYDataStack.git',
    :tag => s.version.to_s
  }
  s.source_files = 'ANDYDataStack/'
  s.frameworks = 'Foundation', 'CoreData'
  s.requires_arc = true
end
