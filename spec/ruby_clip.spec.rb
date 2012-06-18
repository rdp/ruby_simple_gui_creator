require 'common.rb'

describe RubyClip do
  
  it "should be able to get and set clipboard" do
    string = 'from' + rand(33).to_s
    RubyClip.set_clipboard string
    RubyClip.get_clipboard_contents.should == string
  end
  
end