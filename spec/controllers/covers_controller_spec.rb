require 'spec_helper'
  
describe CoversController do
  
  let(:entries) { ['auto_enhance_cvr9781231231230_9781231231230_100_lg.jpg', 'cvr9781231231230_9781231231230_100_lg.jpg', 'cvr9781231231230_9781231231230_lg.jpg', 'auto_enhance_cvr9781231231231_9781231231231_100_lg.jpg', 'cvr9781231231231_9781231231231_100_lg.jpg', 'cvr9781231231231_9781231231231_lg.jpg'] }
  before { Dir.stub(:entries).and_return(entries, entries.clone, entries.clone) }

  context "index" do
    before { get :index }
    
    it { expect(assigns(:files)).to eq(['cvr9781231231230_9781231231230_lg.jpg', 'cvr9781231231231_9781231231231_lg.jpg']) }
  end
  
  context "show" do
    context "without image filter" do
      before { get :show, isbn13: '9781231231230' }
    
      it { expect(assigns(:original)).to eq('cvr9781231231230_9781231231230_lg.jpg') }
      it { expect(assigns(:files)).to eq(['cvr9781231231230_9781231231230_100_lg.jpg']) }
      it { expect(assigns(:filter)).to be_nil }
    end
    
    context "with image filter" do
      before { get :show, isbn13: '9781231231230', filter: "auto_enhance" }

      it { expect(assigns(:filter)).to eq "auto_enhance" }
      it { expect(assigns(:files)).to eq(['auto_enhance_cvr9781231231230_9781231231230_100_lg.jpg']) }
    end
  end
  
  context "quality" do
    context "without image filter" do
      before  { get :quality, quality: '100' }
    
      it { expect(assigns(:files)).to eq({"cvr9781231231230_9781231231230_lg.jpg" => "cvr9781231231230_9781231231230_100_lg.jpg", "cvr9781231231231_9781231231231_lg.jpg" => "cvr9781231231231_9781231231231_100_lg.jpg"}) }
      it { expect(assigns(:filter)).to be_nil }

      context "displays correct image quality" do
        before { Dir.stub(:entries).and_return(entries, entries.clone << ['cvr9781231231231_9781231231231_050_lg.jpg','cvr9781231231231_9781231231231_065_lg.jpg']) }

        it { expect(assigns(:files)).to eq({"cvr9781231231230_9781231231230_lg.jpg" => "cvr9781231231230_9781231231230_100_lg.jpg", "cvr9781231231231_9781231231231_lg.jpg" => "cvr9781231231231_9781231231231_100_lg.jpg"}) }
      end
    end
    
    context "with image filter" do
      before { get :quality, quality: '100', filter: "auto_enhance" }

      it { expect(assigns(:filter)).to eq "auto_enhance" }
      it { expect(assigns(:files)).to eq({"cvr9781231231230_9781231231230_lg.jpg" => "auto_enhance_cvr9781231231230_9781231231230_100_lg.jpg", "cvr9781231231231_9781231231231_lg.jpg" => "auto_enhance_cvr9781231231231_9781231231231_100_lg.jpg"}) }
    end

  end
  
  context "exceptions" do
    before { get :exceptions }
    
    it { expect(assigns(:files)).to eq([]) }
  end
end
