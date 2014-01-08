require 'spec_helper'
  
describe CoversController do
  
  let(:entries) { ['cvr9781231231230_9781231231230_100_lg.jpg', 'cvr9781231231230_9781231231230_lg.jpg', 'cvr9781231231231_9781231231231_100_lg.jpg', 'cvr9781231231231_9781231231231_lg.jpg'] }
  before { Dir.stub(:entries).and_return(entries, entries.clone) }

  context "index" do
    before { get :index }
    
    it { expect(assigns(:files)).to eq(['cvr9781231231230_9781231231230_lg.jpg', 'cvr9781231231231_9781231231231_lg.jpg']) }
  end
  
  context "show" do
    before { get :show, isbn13: '9781231231230' }
    
    it { expect(assigns(:original)).to eq('cvr9781231231230_9781231231230_lg.jpg') }
    it { expect(assigns(:files)).to eq(['cvr9781231231230_9781231231230_100_lg.jpg']) }
  end
  
  context "quality" do
    before  { get :quality, quality: '100' }
    
    it { expect(assigns(:files)).to eq({"cvr9781231231230_9781231231230_lg.jpg" => "cvr9781231231230_9781231231230_100_lg.jpg", "cvr9781231231231_9781231231231_lg.jpg" => "cvr9781231231231_9781231231231_100_lg.jpg"}) }

    context "other qualities than requested" do
      before { Dir.stub(:entries).and_return(entries, entries.clone << ['cvr9781231231231_9781231231231_050_lg.jpg','cvr9781231231231_9781231231231_065_lg.jpg']) }

      it { expect(assigns(:files)).to eq({"cvr9781231231230_9781231231230_lg.jpg" => "cvr9781231231230_9781231231230_100_lg.jpg", "cvr9781231231231_9781231231231_lg.jpg" => "cvr9781231231231_9781231231231_100_lg.jpg"}) }
    end
  end
end
