require 'exifr'
require 'blitline'
require 'open-uri'

#from homeland console
#require '<PATH TO>/blitline_test.rb'
#BlitlineTest.do_the_needfull
#will process all images in the local folder

class BlitlineTest

  @path = CONFIG.onix.cover_image_drop_path
  @blitline_application_id = "3IdSIOrVrQwac42Wb5vmlbQ"
  
  @blitline_qualities = [50, 60, 65, 70, 75, 80, 90, 100]
  
  @cover_image_file_types = [ { suffix: "_lg", max_dimension: 350 } ]

  def self.do_the_needfull(*args)
    if (args.any?)
      image_filename = args.first["image_file_name"]
      process_cover_image(image_filename) if image_filename
    else
      image_filenames = Dir.entries(@path).keep_if { |filename| filename =~ /\.jpg/ }
      image_filenames.each { |image_filename| process_cover_image(image_filename); sleep(30) }
    end
  end

  def self.process_cover_image(image_filename)
    local_high_res_image_path = "#{@path}/#{image_filename}"

    s3_high_res_file_name = new_file_name(image_filename, "_hr")
    s3_high_res_image_path = "spikes/blitline-image-quality/#{s3_high_res_file_name}"
    s3_high_res_url = "http://#{CONFIG.s3.bucket}.s3.amazonaws.com/#{s3_high_res_image_path}"

    # assume the file exists locally
    move_to_s3_strategy = UploadToCdnStrategy::MoveToS3.new
    move_to_s3_strategy.process_file(s3_high_res_image_path, local_high_res_image_path)

    image_exif = EXIFR::JPEG.new(open(s3_high_res_url))

    # assume the file exists on S3
    blitline_resize_hash = {
                              "application_id" => @blitline_application_id,
                              "src" => s3_high_res_url,
                              "postback_url" => CONFIG.onix.blitline_postback_url,
                              "extended_metadata" => true,
                              "functions" => generate_blitline_functions(@cover_image_file_types, image_exif.width, image_exif.height, image_filename, CONFIG.s3.bucket)
                            }
    puts blitline_resize_hash.inspect
    blitline_service = Blitline.new
    blitline_service.add_job_via_hash(blitline_resize_hash)
    blitline_service.post_jobs
  end

  def self.generate_blitline_functions(cover_image_file_types, original_width, original_height, image_filename, bucket)
    file_type = @cover_image_file_types.first
    (width, height) = find_new_image_size(original_width, original_height, file_type[:max_dimension])
    @blitline_qualities.collect do | quality |
      generate_blitline_resize_to_fill_function(width, height, new_file_name(image_filename, "_#{format('%03d', quality)}#{file_type[:suffix]}"), bucket, quality)
    end
  end
   
  def self.generate_blitline_resize_to_fill_function(width, height, output_filename, bucket, quality)
    {
      "name" => "resize_to_fill",
      "params" => {
        "width" => width,
        "height" => height
      },
      "save" => {
        "image_identifier" => output_filename,
        "s3_destination" => {
          "bucket" => bucket,
          "key" => "spikes/blitline-image-quality/#{output_filename}"
        },
        "quality" => quality
      }
    }
  end

  def self.find_new_image_size(width, height, max_dimension)
    width > height ? [max_dimension, calculate_new_dimension(height, width, max_dimension)] : [calculate_new_dimension(width, height, max_dimension), max_dimension]
  end
  
  def self.calculate_new_dimension(top, bottom, max_dimension)
    (top.to_f / bottom.to_f * max_dimension).to_i
  end
  
  # TO DO assume for now original file name will be 12345.jpg, NOT cvr12345.jpg
  def self.new_file_name(original_filename, filename_addition)
    original_filename.gsub(/(\d+)\.jpg/, "cvr\\1_\\1#{filename_addition}.jpg")
  end
  
  def self.get_high_res_masters(isbn_array)
    isbn_array.each do |isbn13|
      copy_image_from_url_to_local(isbn13, "hr", true)
    end
  end
  def self.copy_images_from_url_to_local(isbn_array, type)
    isbn_array.each do |isbn13|
      copy_image_from_url_to_local(isbn13, type, false)
    end
  end

  def self.copy_image_from_url_to_local(isbn13, type, as_master=true)
    filename = as_master ? "#{@path}/#{isbn13}.jpg" : "#{@path}/cvr#{isbn13}_#{isbn13}_#{type}.jpg"
    open(filename, 'wb') do |file|
      puts "copying #{filename}"
      file << open("http://d28hgpri8am2if.cloudfront.net/book_images/cvr#{isbn13}_#{isbn13}_#{type}.jpg").read
    end
  end
end
