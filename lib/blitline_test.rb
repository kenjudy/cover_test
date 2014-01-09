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
  
  @blitline_tests = [
    {quality: 100, function: "despeckle"},
    {quality: 100, function: "auto_enhance"},
    {quality: 100, function: "enhance"},
    {quality: 100, function: "sharpen"},
    {quality: 100, function: "unsharp_mask"},
    {quality: 100, function: "no_op"},

    {quality: 90, function: "despeckle"},
    {quality: 90, function: "auto_enhance"},
    {quality: 90, function: "enhance"},
    {quality: 90, function: "sharpen"},
    {quality: 90, function: "unsharp_mask"},
    {quality: 90, function: "no_op"},

    {quality: 80, function: "despeckle"},
    {quality: 80, function: "auto_enhance"},
    {quality: 80, function: "enhance"},
    {quality: 80, function: "sharpen"},
    {quality: 80, function: "unsharp_mask"},
    {quality: 80, function: "no_op"},

    {quality: 75, function: "despeckle"},
    {quality: 75, function: "auto_enhance"},
    {quality: 75, function: "enhance"},
    {quality: 75, function: "sharpen"},
    {quality: 75, function: "unsharp_mask"},
    {quality: 75, function: "no_op"},
    
  ]
  
  @cover_image_file_types = [ { suffix: "_lg", max_dimension: 350 } ]

  def self.do_the_needfull(*args)
    if (args.any?)
      image_filename = args.first["image_file_name"]
      process_cover_image(image_filename) if image_filename
    else
      image_filenames = Dir.entries(@path).keep_if { |filename| filename =~ /\.jpg/ }
      image_filenames.each { |image_filename| process_cover_image(image_filename); sleep(5) }
    end
  end

  def self.process_cover_image(image_filename)
    local_high_res_image_path = "#{@path}/#{image_filename}"

    # assume the file exists locally
    # move_to_s3_strategy = UploadToCdnStrategy::MoveToS3.new
    # move_to_s3_strategy.process_file(s3_high_res_image_path(image_filename), local_high_res_image_path)

    # assume the file exists on S3
    blitline_service = Blitline.new
    blitline_service.add_job_via_hash(blitline_resize_hash(image_filename))
    puts blitline_service.post_jobs
  end
  
  def self.s3_high_res_image_path(image_filename)
    "spikes/blitline-image-quality/#{new_file_name(image_filename, "_hr")}"
  end
  
  def self.s3_high_res_url(image_filename)
    "http://#{CONFIG.s3.bucket}.s3.amazonaws.com/#{s3_high_res_image_path(image_filename)}"
  end
  
  def self.blitline_resize_hash(image_filename)
    return {
      "application_id" => @blitline_application_id,
      "src" => s3_high_res_url(image_filename),
      "postback_url" => CONFIG.onix.blitline_postback_url,
      "extended_metadata" => true,
      "functions" => generate_blitline_functions(@cover_image_file_types, image_filename, CONFIG.s3.bucket)
    }
   end

  def self.generate_blitline_functions(cover_image_file_types, image_filename, bucket)
    image_exif = EXIFR::JPEG.new(open(s3_high_res_url(image_filename)))
    file_type = cover_image_file_types.first
    constraining_dimension = image_exif.width > image_exif.height ? "width" : "height"
    
    @blitline_tests.collect do | test |
      generate_blitline_resize_to_fit_function(constraining_dimension, file_type[:max_dimension], new_file_name(image_filename, "_#{format('%03d', test[:quality])}#{file_type[:suffix]}"), bucket, test[:function], test[:quality])
    end
  end
   
  def self.generate_blitline_resize_to_fit_function(constraining_dimension, max_dimension, output_filename, bucket, function, quality)
    {
      "name" => "resample",
      "params" => {
          "density" => 72.0
      },
      "functions" => [
        "name" => "resize_to_fit",
        "params" => {
           constraining_dimension => max_dimension
        },
        "functions" => [
          {
            "name" => function,
            "save" => {
              "quality" => quality,
              "image_identifier" => output_filename,
              "s3_destination" => {
                "bucket" => bucket,
                "key" => "spikes/blitline-image-quality/#{function + '_' unless function == "no_op"}#{output_filename}"
              }
            }
          }
        ]
      ]
    }
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
