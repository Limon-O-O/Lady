Pod::Spec.new do |s|
  s.name             = "Lady"
  s.version          = "0.1.0"
  s.summary          = "High Pass Skin Smoothing."

  s.description      = <<-DESC
                       An implementation of High Pass Skin Smoothing using CoreImage.framework.
                       DESC

  s.homepage         = "https://github.com/Limon-O-O/Lady"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Limon" => "fengninglong@gmail.com" }
  s.source           = { :git => "https://github.com/Limon-O-O/Lady.git", :tag => s.version.to_s }
  s.social_media_url  = "https://twitter.com/Limon______"

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Lady/*.swift'
  s.resources    = 'Lady/Resources/*.cikernel'

end
