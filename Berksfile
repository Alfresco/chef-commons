source "https://api.berkshelf.com"

cookbook 'line', git: 'https://github.com/someara/line-cookbook.git', tag: "v0.6.3"
cookbook 'maven', git: 'git://github.com/maoo/maven.git', tag: "v1.2.0-fork"

group :integration do
  cookbook 'commons_test', :path => './test/cookbooks/commons_test'
  cookbook 'line', git: 'https://github.com/someara/line-cookbook.git', tag: "v0.6.3"
  cookbook 'maven', git: 'git://github.com/maoo/maven.git', tag: "v1.2.0-fork"
end

metadata
