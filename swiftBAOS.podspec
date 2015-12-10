Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "swiftBAOS"
s.summary = "swift Framework for BAOS 777 REST-API"
s.requires_arc = true

# 2
s.version = "0.1.1"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Henrik Engelbrink" => "hengel2810@gmail.com" }

# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/hengel2810/swiftBAOS"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/hengel2810/swiftBAOS.git", :tag => "#{s.version}"}

# 7
# s.dependency 'Alamofire', '~> 2.0'
s.dependency 'SwiftHTTP', '~> 1.0.0'
s.dependency 'Starscream', '~> 1.0.0'

# 8
s.source_files = "swiftBAOS/**/*.{swift}"

# 9
# s.resources = "swiftBAOS/**/*.{png,jpeg,jpg,storyboard,xib}"

end
