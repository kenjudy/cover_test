class CoversController < ApplicationController

  before_filter :set_image_filter

  def index
    @files = new_files({quality: SELECTABLE_QUALITIES.last})
  end


  def show
    @isbn13 = params['isbn13']
    @original = filename_from_isbn(params['isbn13'])
    @files = new_files({isbn13: params['isbn13']})
  end
  
  def quality
    @quality = format('%03d', params["quality"])
    originals = original_covers
    new_files = new_files({quality: @quality})
    @files = {}
    
    originals.each do |original| 
      new_file = filename_from_isbn(isbn_from_filename(original), { quality: @quality, filter: @filter })
      @files[original] = new_file if new_files.include?(new_file)
    end
  end
  
  def exceptions
    @files = original_covers.keep_if do |filename|
      new_files( {isbn13: isbn_from_filename(filename)} ).empty?
    end
  end
  
  private
  
  def set_image_filter 
    @filter = params["filter"] && params["filter"] != "no_op" ? params["filter"] : nil
  end
  
  def original_covers
    Dir.entries("#{Rails.root}#{COVER_IMAGE_DIR}").keep_if{ |file| file =~ /\d{13,13}_lg\.jpg/ }
  end
  
  def new_files(args = {})
    quality_match = args[:quality] || /\d\d\d/
    isbn_match = args[:isbn13] || /\d{13,13}/
    prefix = args[:filter] || @filter || "cvr"
    Dir.entries("#{Rails.root}#{COVER_IMAGE_DIR}").keep_if{ |file| file =~ /#{isbn_match}_#{quality_match}_lg\.jpg$/ && file =~ /^#{prefix}/ }
  end
 
  def filename_from_isbn(isbn, options = {})
    filter = options[:filter]
    quality = options[:quality]
    "#{filter + "_" if filter}cvr#{isbn}_#{isbn}_#{quality + "_" if quality}lg.jpg"
  end
  
  def isbn_from_filename(filename)
    filename.gsub(/^cvr(\d{13,13})_.*/, '\1')
  end
end