require 'spec_helper'

describe ImageProcessor do
  let(:s3_bucket) { AppConstants::S3_BUCKET }
  let(:s3_cover_images_path) { AppConstants::S3_COVER_IMAGES_PATH }
  let(:cdn_book_url) { AppConstants::CDN_BOOK_URL }
  let(:image_qualities) { [100,90] }
  let(:image_filters) { [:unsharp_mask, :no_op] }
  let(:test_cases) { image_qualities.map { |quality| image_filters.map { |function| { quality: quality, function: function }}}.flatten }
  let(:image_exif) { double("Exif", height: 300, width: 250) }
  let(:blitline_service) { double(Blitline).as_null_object}
  let(:move_to_s3) { double(UploadToCdnStrategy::MoveToS3).as_null_object }

  
  before do
    ImageProcessor.stub(get_image_exif: image_exif)
    ImageProcessor.stub(:drop_cover_image)
    
    Blitline.stub(new: blitline_service)
    UploadToCdnStrategy::MoveToS3.stub(new: move_to_s3)
  end
  
  context "test_cases for each image quality and filter" do
    subject { ImageProcessor.test_cases(image_qualities, image_filters) }
    
    it { should == test_cases }
  end
  
  context "isbn_from_filename" do
    subject { ImageProcessor.isbn_from_filename("9711231231231.jpg")}
    
    it { should == "9711231231231" }
  end
  
  context "website_cover_filename_convention" do
    subject { ImageProcessor.website_cover_filename_convention("9711231231231") }
    it { should == "cvr9711231231231_9711231231231.jpg" }
    
    context "accepts filename addition" do
      subject { ImageProcessor.website_cover_filename_convention("9711231231231", "arbitrary_file_suffix") }
      it { should == "cvr9711231231231_9711231231231_arbitrary_file_suffix.jpg" }
    end
  end

  context "s3_cover_image_path" do
    subject { ImageProcessor.s3_cover_image_path("9711231231231") }
    it { should == "#{s3_cover_images_path}cvr9711231231231_9711231231231.jpg" }
    context "accepts filename addition" do
      subject { ImageProcessor.s3_cover_image_path("9711231231231", "arbitrary_file_suffix") }
      it { should == "#{s3_cover_images_path}cvr9711231231231_9711231231231_arbitrary_file_suffix.jpg" }
    end
  end

  context "s3_high_res_image_path" do
    subject { ImageProcessor.s3_high_res_image_path("9711231231231") }
    it { should == "#{s3_cover_images_path}cvr9711231231231_9711231231231_hr.jpg" }
  end

  context "s3_high_res_image_url" do
    subject { ImageProcessor.s3_high_res_image_url("9711231231231") }
    it { should == "http://#{s3_bucket}.s3.amazonaws.com/#{s3_cover_images_path}cvr9711231231231_9711231231231_hr.jpg" }
  end
  
  context "longest_dimension" do
    subject { ImageProcessor.longest_dimension(image_exif) }
    it { should == :height }
  end
  
  context "blitline_new_image_instructions" do
    let(:options) {{ constraining_dimension: :height, filename_addition: "unsharp_mask_100_lg", 
                     function: :unsharp_mask, isbn13: "9711231231231",
                     max_dimension: 350, quality: 100, s3_bucket: s3_bucket, 
                     blitline_function_params: { "sigma" => 0.5, "amount" => 1 } }}
    subject { ImageProcessor.blitline_new_image_instructions(options) }
    
    it { should == JSON.parse(blitline_new_image_instruction) }
  end
  
  context "blitline_new_images" do
    let(:image_qualities) { [100, 90] }
    let(:image_filters) { [:unsharp_mask, :no_op] }
    let(:image_sizes) { [ { suffix: "lg", max_dimension: 350 }, { suffix: nil, max_dimension: 250 } ] }
    let(:blitline_function_params) { {sharpen: { "sigma" => 0.5 }, unsharp_mask: { "sigma" => 0.5, "amount" => 1 }}}
    subject { ImageProcessor.blitline_new_images(image_sizes: image_sizes, 
                                                 image_qualities: image_qualities, 
                                                 image_filters: image_filters, 
                                                 blitline_function_params: blitline_function_params, 
                                                 s3_bucket: s3_bucket, 
                                                 isbn13: "9711231231231") }

    it { should have(8).items }
    its(:first) { should == JSON.parse(blitline_new_image_instruction) }

    context "with one iteration creates one image" do
      let(:image_qualities) { [100] }
      let(:image_filters) { [:unsharp_mask] }
      let(:image_sizes) { [ { suffix: "lg", max_dimension: 350 } ] }

      it { should have(1).items }
      its(:first) { should == JSON.parse(blitline_new_image_instruction) }
    end
    
    context "blitline_resize_hash" do
      subject { ImageProcessor.blitline_resize_hash("9711231231231") }

      its(["application_id"]) { should == "3IdSIOrVrQwac42Wb5vmlbQ" }
      its(["src"]) { should == "http://sns-dev-test-2.s3.amazonaws.com/spikes/blitline-image-quality/cvr9711231231231_9711231231231_hr.jpg" }
      its(["extended_metadata"]) { should be_true }
      its(["functions"]) { should have(AppConstants::SELECTABLE_QUALITIES.size * AppConstants::IMAGE_FILTERS.size).items }
    end
    
    context "process_cover_image" do
      before do
        ImageProcessor.stub(blitline_resize_hash: { sample: "Sample Response" }) 
        File.stub(exists?: true)
      end
      
      context "external dependecies" do
        after { ImageProcessor.process_cover_image("9711231231231.jpg") }
      
        context "blitline" do
          it("adds job") { expect(blitline_service).to receive(:add_job_via_hash).with({ sample: "Sample Response" })}
          it("posts job") { expect(blitline_service).to receive(:post_jobs)}
        end
      
        context "s3" do
          it("processes file") { expect(move_to_s3).to receive(:process_file).with("spikes/blitline-image-quality/cvr9711231231231_9711231231231_hr.jpg", "#{Rails.root}/tmp/covers/9711231231231.jpg") }
        end
      
      end

      context "image file doesn't exist" do
        before { File.stub(exists?: false) }
        
        context "drops copy from web" do
          after { ImageProcessor.process_cover_image("9711231231231.jpg") }
          
          it { expect(ImageProcessor).to receive(:drop_high_res_images).with(['9711231231231']) }
        end

        context "doesn't raise error" do
          before { ImageProcessor.stub(:drop_high_res_images).and_raise(StandardError) }

          it { expect{ImageProcessor.process_cover_image("9711231231231.jpg")}.to_not raise_error}

        end
      end

    end
    
    context "run" do
      before { ImageProcessor.stub(:sleep) }
      context "accepts filename arguments" do
        after { ImageProcessor.run("sample1.jpg", "sample2.jpg") }
        
        it("processes files") { expect(ImageProcessor).to receive(:process_cover_image).twice.with(/sample[1,2]\.jpg/) }
      end
      
      context "no arguments" do
        before { Dir.stub(entries: ["sample1.jpg", "sample2.jpg"]) }
        after { ImageProcessor.run }
        
        it("processes files in drop folder") { expect(ImageProcessor).to receive(:process_cover_image).twice.with(/sample[1,2]\.jpg/) }
      end
    end
    
    context "drop_cover_image" do
      after { ImageProcessor.drop_cover_images(["isbn1", "isbn2"], "hr") }
      
      it("copies image") { expect(ImageProcessor).to receive(:copy_image).twice.with(/#{cdn_book_url}cvrisbn[1,2]_isbn[1,2]_hr.jpg/,
                                                                                     /#{Rails.root}\/tmp\/covers\/cvrisbn[1,2]_isbn[1,2]_hr\.jpg/) }
    end
    context "drop_high_res_images" do
      after { ImageProcessor.drop_high_res_images(["isbn1", "isbn2"]) }
      
      it("copies image") { expect(ImageProcessor).to receive(:copy_image).twice.with(/#{cdn_book_url}cvrisbn[1,2]_isbn[1,2]_hr.jpg/,
                                                                                     /#{Rails.root}\/tmp\/covers\/isbn[1,2]\.jpg/) }
    end
    
  end
  
  def blitline_new_image_instruction
    <<-EOS
    {
      "name": "resize_to_fit",
      "params": {
        "height": 350
      },
      "functions": [
        {
          "name": "unsharp_mask",
          "params": {
            "sigma": 0.5,
            "amount": 1
          },
          "save": {
            "quality": 100,
            "image_identifier": "cvr9711231231231_9711231231231_unsharp_mask_100_lg.jpg",
            "s3_destination": {
              "bucket": "sns-dev-test-2",
              "key": "spikes/blitline-image-quality/cvr9711231231231_9711231231231_unsharp_mask_100_lg.jpg"
            }
          }
        }
      ]
    }
    EOS
  end
end