Pod::Spec.new do |s|
    s.name         = "NDAudioSuite"
    s.version      = "2.1.0"
    s.summary      = "An audio library with audio streaming and downloading built in."
    s.description  = <<-DESC
                   NDAudioSuite was written so that you will no longer have to write audio
                   players or file downloaders for your app. It has a built in audio player
                   that can stream audio from a URL. It also has a built in download manager 
                   for files.
                    DESC

    s.homepage     = "http://www.metova.com"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.authors      = {
        "Drew Pitchford" => "drew.pitchford@metova.com",
        "Nick Sinas" => "nick.sinas@metova.com"
    }

    s.platform     = :ios, "8.0"
    s.source       = { :git => "https://github.com/metova/NDAudioSuite.git", :tag => s.version.to_s }

    s.source_files  = "NDAudioPlayer"
    s.exclude_files = "NDAudioSuite/NDAudioPlayer/VCs"
end
