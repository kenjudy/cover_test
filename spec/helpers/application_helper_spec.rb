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
    it { should == "250 x 300"}
    context "delim" do
      subject { image_dimensions(filename, ", ")}
      it { should == ", 250 x 300" }
    end
    context "no exifr" do
      before { EXIFR::JPEG.stub(:new).and_raise(StandardError) }
      it { should == nil }
    end
  end
  
end
