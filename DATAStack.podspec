Pod::Spec.new do |s|
  s.name = "DATAStack"
  s.version = "3.1.1"
  s.summary = "Core Data stack set up boilerplate"
  s.description = <<-DESC
                   * Feeling tired of having Core Data boilerplate in your AppDelegate?
                   * No more.
                   DESC
  s.homepage = "https://github.com/3lvis/DATAStack"
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE.md'
  }
  s.author = { "Elvis Nunez" => "elvisnunez@me.com" }
  s.social_media_url = "http://twitter.com/3lvis"
  s.platform = :ios, '7.0'
  s.source = {
    :git => 'https://github.com/3lvis/DATAStack.git',
    :tag => s.version.to_s
  }
  s.source_files = 'Source/'
  s.frameworks = 'Foundation', 'CoreData'
  s.requires_arc = true
  s.dependency 'NSObject-HYPTesting', '~> 1.2'
end
