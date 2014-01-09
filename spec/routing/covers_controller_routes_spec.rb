require 'spec_helper'

describe CoversController do

  # root 'covers#index'
  # get 'covers/:isbn13' => 'covers#show', as: 'cover'
  # get 'quality/:quality' => 'covers#quality', as: 'quality'
  # get 'covers/exceptions' => 'covers#exceptions', as: 'exceptions'

  context "index" do
    subject { {get: "/"} }
    
    it { should route_to(controller: "covers", action: "index") }
  end
  
  context "show" do
    subject { {get: "/covers/9781231231234"} }
    
    it { should route_to(controller: "covers", action: "show", isbn13: "9781231231234") }
    
    context "bad isbn" do
      subject { {get: "/covers/978"} }
      
      it { should_not route_to(controller: "covers", action: "show", isbn13: "978") }
    end
    context "apply filter" do
      subject { {get: "/covers/9781231231234/foo"} }
      
      it { should route_to(controller: "covers", action: "show", isbn13: "9781231231234", filter: "foo") }
    end
  end
  
  context "quality" do
    subject { {get: "/quality/50"} }

    it { should route_to(controller: "covers", action: "quality", quality: "50") }
    
    context "bad quality number" do
      subject { {get: "/quality/5"} }

      it { should_not route_to(controller: "covers", action: "quality", quality: "5") }
    end

    context "apply filter" do
      subject { {get: "/quality/50/foo"} }

      it { should route_to(controller: "covers", action: "quality", quality: "50", filter: "foo") }
    end
  end

  context "exceptions" do
    subject { {get: "/exceptions"} }
    
    it { should route_to(controller: "covers", action: "exceptions") }
  end
  
end