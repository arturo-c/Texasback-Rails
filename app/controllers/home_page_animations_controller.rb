class HomePageAnimationsController < ApplicationController
  layout 'admin'  
  
  def index
    @animations = HomePageAnimation.all
  end
  
  def save
    if params[:active_animation]
      HomePageAnimation.all.each do |item|
        item.update_attribute(:active, (item.id.to_s == params[:active_animation]))
      end
    end
    
    expire_page(homepage_path)
    
    flash[:notice] = "Home page animation has been updated successfully."
    
    redirect_to home_page_animations_path
  end
end
