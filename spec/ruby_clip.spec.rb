require 'common.rb'
require '../ruby_clip'

describe RubyClip do
  
  it "should be able to get and set clipboard" do
    string = 'from' + rand(33).to_s
    RubyClip.set_clipboard string
    RubyClip.get_clipboard.should == string
  end
  
  
end