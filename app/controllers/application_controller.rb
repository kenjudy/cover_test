class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
 
  def filename_from_isbn(isbn, quality = nil)
    "cvr#{isbn}_#{isbn}_#{quality + "_" if quality}lg.jpg"
  end
  
  def isbn_from_filename(filename)
    filename.gsub(/^cvr(\d{13,13})_.*/, '\1')
  end
  
end
