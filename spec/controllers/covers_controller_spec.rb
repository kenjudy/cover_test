require 'spec_helper'
  
describe CoversController do
  let(:cvr_original) { 'cvr9781231231230_9781231231230_lg.jpg' }
  let(:cvr_new) { 'cvr9781231231230_9781231231230_no_op_100_lg.jpg' }
  let(:cvr_feature) { 'cvr9781231231230_9781231231230_auto_enhance_100_lg.jpg' }
  let(:cvr_original_2) { 'cvr9781231231231_9781231231231_lg.jpg' }
  let(:cvr_new_2) { 'cvr9781231231231_9781231231231_no_op_100_lg.jpg' }
  let(:cvr_feature_2) { 'cvr9781231231231_9781231231231_auto_enhance_100_lg.jpg' }
  
  let(:entries) { [cvr_new, cvr_feature, cvr_original, cvr_feature_2, cvr_new_2, cvr_original_2] }
  before { Dir.stub(:entries).and_return(*(0..10).map { entries.clone }) }

  context "index" do
    before { get :index }
    
    it { expect(assigns(:files)).to eql([cvr_new, cvr_new_2]) }
  end
  
  context "show" do
    context "without image filter" do
      before { get :show, isbn13: '9781231231230' }
    
      it { expect(assigns(:isbn13)).to eql('9781231231230') }
      it { expect(assigns(:original)).to eql(cvr_original) }
      it { expect(assigns(:files)).to eql([cvr_new]) }
      it { expect(assigns(:filter)).to eql(:no_op) }
    end
    
    context "with image filter" do
      before { get :show, isbn13: '9781231231230', filter: "auto_enhance" }

      it { expect(assigns(:filter)).to eql :auto_enhance }
      it { expect(assigns(:files)).to eql([cvr_feature]) }
    end
    
    context "with all image filters" do
      before { get :show, isbn13: '9781231231230', filter: "all" }

      it { expect(assigns(:filter)).to eql :all }
      it { expect(assigns(:files)).to eql([cvr_feature, cvr_new]) }

    end
  end
  
  context "quality" do
    context "without image filter" do
      before  { get :quality, quality: '100' }
    
      it { expect(assigns(:files)).to eql({cvr_original => cvr_new, cvr_original_2 => cvr_new_2}) }
      it { expect(assigns(:filter)).to eql(:no_op) }

      context "displays correct image quality" do
        before { Dir.stub(:entries).and_return(entries, entries.clone << ['cvr9781231231231_9781231231231_050_lg.jpg','cvr9781231231231_9781231231231_065_lg.jpg']) }

        it { expect(assigns(:files)).to eql({cvr_original => cvr_new, cvr_original_2 => cvr_new_2}) }
      end
    end
    
    context "with image filter" do
      before { get :quality, quality: '100', filter: "auto_enhance" }

      it { expect(assigns(:filter)).to eql :auto_enhance }
      it { expect(assigns(:files)).to eql({cvr_original => cvr_feature, cvr_original_2 => cvr_feature_2}) }
    end

  end
  
  context "exceptions" do
    before { get :exceptions }
    
    it { expect(assigns(:files)).to eql([]) }
  end
end
