Pod::Spec.new do |s|
  s.name = 'Babel'
  s.version = '0.5.1'
  s.summary = 'JSON! *Pure Swift*, failure driven, inferred *but unambiguous*, with powerful *but optional* operators.'

  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { 'Mathew Huusko V' => 'mhuusko5@gmail.com' }
  s.homepage = 'https://github.com/mhuusko5/Babel'
  s.social_media_url = 'https://twitter.com/mhuusko5'
  s.source = { :git => 'https://github.com/mhuusko5/Babel.git', :tag => s.version.to_s }

  s.platforms = { :osx => '10.9', :ios => '8.0', :tvos => '9.0', :watchos => '2.0' }
  s.requires_arc = true

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/Value.swift', 'Sources/Decoding.swift', 'Sources/JSON.swift'
  end

  s.subspec 'Decodable' do |ss|
    ss.dependency 'Babel/Core'
    ss.source_files = 'Sources/Decodable.swift'
  end

  s.subspec 'Operators' do |ss|
    ss.dependency 'Babel/Decodable'
    ss.source_files = 'Sources/Operators.swift'
  end

  s.subspec 'Foundation' do |ss|
    ss.dependency 'Babel/Decodable'
    ss.frameworks = 'Foundation'
    ss.source_files = 'Sources/Foundation.swift'
  end

  s.subspec 'Helpers' do |ss|
    ss.source_files = 'Sources/Helpers.swift'
  end

  s.default_subspecs = 'Core', 'Decodable', 'Operators', 'Foundation'
end
