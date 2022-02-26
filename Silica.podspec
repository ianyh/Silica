Pod::Spec.new do |s|
  s.name          = "Silica"
  s.version       = "0.3.4"
  s.summary       = "A framework for Cocoa window management."
  s.description   = <<-DESC
                    Silica is a framework for window management on macOS.
                    DESC
  s.homepage      = "https://github.com/ianyh/Silica"
  s.license       = 'MIT'
  s.authors       = { "Ian Ynda-Hummel" => "ianynda@gmail.com", "Steven Degutis" => "steven@cleancoders.com" }
  s.platform      = :osx, '10.11'
  s.source        = { :git => "https://github.com/ianyh/Silica.git", :tag => '0.3.3', :submodules => true }
  s.source_files  = 'Silica', 'Silica/**/*.{h,m}', 'CGSInternal/*.h'
  s.exclude_files = 'Silica/Exclude'
  s.frameworks    = 'AppKit', 'IOKit', 'Carbon'
  s.requires_arc  = true
end
