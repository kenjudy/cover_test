require 'exifr'
require 'blitline'
require 'open-uri'

#from homeland console
#require '<PATH TO>/blitline_test.rb'
#BlitlineTest.do_the_needfull
#will process all images in the local folder

class ImageProcessor

  @cover_image_drop_path = AppConstants::COVER_IMAGE_DROP_PATH
  @image_qualities = AppConstants::SELECTABLE_QUALITIES
  @image_filters = AppConstants::IMAGE_FILTERS
  @s3_cover_image_path = AppConstants::S3_COVER_IMAGES_PATH
  @s3_bucket = AppConstants::S3_BUCKET
  @cdn_book_url = AppConstants::CDN_BOOK_URL
  
  @image_sizes = [ { suffix: "lg", max_dimension: 350 } ]

  @blitline_application_id = AppConstants::BLITLINE_APP_ID
  @blitline_function_params =
    {
      sharpen: { "sigma" => 0.5 },
      unsharp_mask: { "sigma" => 0.5, "amount" => 1 }
    }
    
  def self.run(*args)
    image_filenames = args.any? ? args : Dir.entries(@cover_image_drop_path).keep_if { |filename| filename =~ /\.jpg/ }
    image_filenames.each { |image_filename| process_cover_image(image_filename); sleep(5) }
  end

  def self.process_cover_image(image_filename)
    puts "---- process: #{image_filename}"
    isbn13 = isbn_from_filename(image_filename)
    file_path = drop_path(image_filename)

    begin
      drop_high_res_images([isbn13]) unless File.exists?(file_path)
      UploadToCdnStrategy::MoveToS3.new.process_file(s3_high_res_image_path(isbn13), file_path)
      post_blitline_job(blitline_resize_hash(isbn13))
    rescue => e
      puts "---- failed: #{image_filename}: #{e.message} #{e.backtrace}"
    end
  end
  
  def self.post_blitline_job(blitline_instructions)
    blitline_service = Blitline.new
    blitline_service.add_job_via_hash(blitline_instructions)
    puts blitline_service.post_jobs
  end
  
  def self.drop_high_res_images(isbn_array)
    isbn_array.each do |isbn13|
      copy_image("#{@cdn_book_url}#{website_cover_filename_convention(isbn13, "hr")}", drop_path("#{isbn13}.jpg"))
    end
  end
  
  def self.drop_cover_images(isbn_array, type)
    isbn_array.each do |isbn13|
      copy_image("#{@cdn_book_url}#{website_cover_filename_convention(isbn13, type)}", drop_path(website_cover_filename_convention(isbn13, type)))
    end
  end
  
  def self.copy_image(source_image, target_image)
    File.open(target_image, 'wb') do |file|
      file << File.open(source_image).read
    end
    puts "dropped #{source_image}"
  end

  def self.blitline_resize_hash(isbn13)
    options = {
      image_sizes: @image_sizes,
      image_qualities: @image_qualities,
      image_filters: @image_filters,
      blitline_function_params: @blitline_function_params,
      s3_bucket: @s3_bucket,
      isbn13: isbn13
    }
    return {
      "application_id" => @blitline_application_id,
      "src" => s3_high_res_image_url(isbn13),
      "extended_metadata" => true,
      "functions" => blitline_new_images(options)
    }
   end

  def self.blitline_new_images(options)
    blitline_function_params = options[:blitline_function_params]
    image_filters = options[:image_filters]
    image_qualities = options[:image_qualities]
    image_sizes = options[:image_sizes]
    isbn13 = options[:isbn13]
    s3_bucket = options[:s3_bucket]
           
    constraining_dimension = longest_dimension(get_image_exif(isbn13))
    
    image_sizes.map do |file_type|
      test_cases(image_qualities, image_filters).collect do | test |
        
        filename_addition = "#{test[:function]}_#{format('%03d', test[:quality])}_#{file_type[:suffix]}"
        
        blitline_new_image_instructions({ 
                                          blitline_function_params: blitline_function_params[test[:function]],
                                          filename_addition: filename_addition, 
                                          function: test[:function], 
                                          isbn13: isbn13, 
                                          max_dimension: file_type[:max_dimension], 
                                          quality: test[:quality], 
                                          s3_bucket: s3_bucket,
                                          constraining_dimension: constraining_dimension
                                          })

      end.flatten
    end.flatten
  end
  
  def self.blitline_new_image_instructions(options)
    blitline_function_params = options[:blitline_function_params]
    constraining_dimension = options[:constraining_dimension]
    filename_addition = options[:filename_addition]
    function = options[:function]
    isbn13 = options[:isbn13]
    max_dimension = options[:max_dimension]
    quality = options[:quality]
    s3_bucket = options[:s3_bucket]
    
    {
      "name" => "resize_to_fit",
      "params" => {
         constraining_dimension.to_s => max_dimension
      },
      "functions" => [
        {
          "name" => function.to_s,
          "params" => blitline_function_params ? blitline_function_params : {},
          "save" => {
            "quality" => quality,
            "image_identifier" => website_cover_filename_convention(isbn13, filename_addition),
            "s3_destination" => {
              "bucket" => s3_bucket,
              "key" => s3_cover_image_path(isbn13, filename_addition)
            }
          }
        }
      ]
    }
  end
  
  def self.drop_path(image_filename)
    "#{@cover_image_drop_path}#{image_filename}"
  end
  
  def self.longest_dimension(image_exif)
    image_exif.width > image_exif.height ? :width : :height
  end
  
  def self.get_image_exif(isbn13)
    EXIFR::JPEG.new(open(s3_high_res_image_url(isbn13)))
  end
  
  def self.s3_high_res_image_url(isbn13)
    "http://#{@s3_bucket}.s3.amazonaws.com/#{s3_high_res_image_path(isbn13)}"
  end
  
  def self.s3_high_res_image_path(isbn13)
    "#{@s3_cover_image_path}#{website_cover_filename_convention(isbn13, "hr")}"
  end
  
  def self.s3_cover_image_path(isbn13, filename_addition = nil)
    "#{@s3_cover_image_path}#{website_cover_filename_convention(isbn13, filename_addition)}"
  end

  def self.website_cover_filename_convention(isbn13, filename_addition = nil)
    ["cvr#{isbn13}",isbn13,filename_addition].compact.join("_") << ".jpg"
  end
  
  def self.isbn_from_filename(filename)
    filename.gsub(/(\d{13}).*/, '\1')
  end

  def self.test_cases(image_qualities, image_filters) 
    image_qualities.map { |quality| image_filters.map { |function| { quality: quality, function: function }}}.flatten
  end

end
