class Admin::FellowshipsController < ApplicationController
  def create
    @fellowship = Fellowship.new(:name => params[:name].to_s.gsub("null", ""))
    
    @fellowship.save
    
    respond_to do |wants|
      wants.html { redirect_to(admin_path) }
      wants.js      
    end
  end
end
