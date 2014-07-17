$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name    = "vagrant_ci"
  s.version = "0.0.1"
  s.authors = ["Chris Griffiths"]
  s.email   = ["Christopher_Griffiths@hotmail.com"]
  s.homepage= "https://github.com/ChrisGriffiths/vagrant_ci.git"
  s.summary = "Using to create and manage vagrant virtual machines"
	
  s.files = Dir.glob("lib/**/*")
  
  s.require_paths = ["lib"]
end
