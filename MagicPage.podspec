

Pod::Spec.new do |spec|

  spec.name         = "MagicPage"
  spec.version      = "1.0"
  spec.summary      = "amazing page"

  spec.homepage     = "https://github.com/zhuyitian/MagicPage"
  spec.license      = "MIT"
  spec.author             = { "Talan" => "16657120403@163.com" }
  spec.source       = { :git => "https://github.com/zhuyitian/MagicPage.git", :tag => "1.0" }
  spec.source_files  = "MagicPage/Classes/MagicPage/**/*.swift"
  spec.platform     = :ios, "10.0"

end
