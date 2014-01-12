class CoversController < ApplicationController

  before_filter :set_image_filter
  
  def index
    @files = new_files({quality: selectable_qualities.last, filter: :no_op})
  end


  def show
    @isbn13 = params['isbn13']
    @original = filename_from_isbn(params['isbn13'])
    if @filter == :all
      @files = image_filters.map { |filter| new_files({isbn13: params['isbn13'], filter: filter}) }.flatten
      @files.sort! { |a,b| a.gsub(/.*\d_([\w_]+)_(\d{3})_/, '\2\1') <=>  b.gsub(/.*\d_([\w_]+)_(\d{3})_/, '\2\1') }
    else
      @files = new_files({isbn13: params['isbn13'], filter: @filter})
    end
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
  
  def selectable_qualities
    AppConstants::SELECTABLE_QUALITIES
  end
  
  def image_filters
    AppConstants::IMAGE_FILTERS
  end
  
  def cover_image_dir
    AppConstants::COVER_IMAGE_DIR
  end
  
  def set_image_filter 
    @filter = params["filter"] && params["filter"] != "no_op" ? params["filter"].to_sym : :no_op
  end
  
  def original_covers
    Dir.entries("#{Rails.root}#{cover_image_dir}").keep_if{ |file| file =~ /\d{13,13}_lg\.jpg/ }
  end
  
  def new_files(args = {})
    quality_match = args[:quality] || /\d\d\d/
    isbn_match = args[:isbn13] || /\d{13,13}/
    filter_match = args[:filter] ? "_" << args[:filter].to_s : /[\w_]+/
    Dir.entries("#{Rails.root}#{cover_image_dir}").keep_if{ |file| file =~ /#{isbn_match}#{filter_match}_#{quality_match}_lg\.jpg$/ }
  end
 
  def filename_from_isbn(isbn, options = {})
    filter = options[:filter]
    quality = options[:quality]
    "cvr#{isbn}_#{isbn}#{"_" << filter.to_s if filter}_#{quality + "_" if quality}lg.jpg"
  end
  
  def isbn_from_filename(filename)
    filename.gsub(/^cvr(\d{13,13})_.*/, '\1')
  end
end