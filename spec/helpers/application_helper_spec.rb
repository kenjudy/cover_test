require 'spec_helper'
  
describe ApplicationHelper do
  let(:filename) { 'auto_enhance_cvr9781231231230_9781231231230_100_lg.jpg' }
  
  context "isbn_from_filename" do
    subject { isbn_from_filename(filename)}
    it { should == '9781231231230'}
  end
  
  context "quality_from_filename" do
    subject { quality_from_filename(filename)}
    it { should == '100'}
  end
  
  context "filesize" do
    before { File.stub(size: 80730) }
    subject { filesize(filename)}
    it { should == '78.84'}
  end
  
  context "image_dimensions" do
    before { EXIFR::JPEG.stub(new: double(EXIFR::JPEG, width: 250, height: 300)) }
    subject { image_dimensions(filename)}
    it { should == {width: 250, height: 300}}
     context "no exifr" do
      before { EXIFR::JPEG.stub(:new).and_raise(StandardError) }
      it { should == {} }
    end
  end
  
  context "image_dimensions_style" do
    subject { image_dimensions_style({width: 250, height: 300})}
    it { should == "max-width: 250px;width: 250px; height: 300px;"}
  end
end
