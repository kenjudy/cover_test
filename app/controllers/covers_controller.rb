class CoversController < ApplicationController

  def index
    @files = original_covers
  end


  def show
    @original = filename_from_isbn(params['isbn13'])
    @files = new_files({isbn13: params['isbn13']})
  end
  
  def quality
    @quality = format('%03d', params["quality"])
    originals = original_covers
    comparisons = new_files({quality: @quality})
    @files = {}
    
    originals.each do |original| 
      comparison = filename_from_isbn(isbn_from_filename(original), @quality)
      @files[original] = comparison if comparisons.include?(comparison)
    end
  end
  
  def exceptions
    
  end
  
  private
  
  def original_covers
    Dir.entries("#{Rails.root}/public/images/covers").keep_if{ |file| file =~ /\d{13,13}_lg\.jpg/ }
  end
  
  def new_files(args = {})
    quality_match = args[:quality] || /\d\d\d/
    isbn_match = args[:isbn13] || /\d{13,13}/
    Dir.entries("#{Rails.root}/public/images/covers").keep_if{ |file| file =~ /#{isbn_match}_#{quality_match}_lg\.jpg/ }
  end
end