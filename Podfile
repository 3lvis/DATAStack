use_frameworks!

abstract_target 'CocoaPods' do
  pod 'DATASource'

  target 'DemoObjectiveC' do
  end

  target 'DemoSwift' do
  end
end

target 'Tests' do
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end

    installer.pods_project.build_configurations.each do |build_configuration|
        puts "Add code signing to pods"
        build_configuration.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = "#{ENV["PROVISIONING_PROFILE_TEAM_ID"]}"
    end
end
