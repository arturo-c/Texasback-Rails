class Admin::MediaEntriesController < ApplicationController
  layout 'admin'  
  
  cache_sweeper :media_entry_sweeper, :only => [ :create, :update, :order ]
  
  before_filter :load_lookups, :except => :index
  
  def index
    @active = MediaEntry.active
    @inactive = MediaEntry.inactive
  end
  
  def new
    @media_entry = MediaEntry.new(:italicize_source => true, :quote_article => true)
  end
  
  def create
    @media_entry = MediaEntry.new(params[:media_entry])
    
    if @media_entry.save
      flash[:notice] = "This media entry has been added successfully."
      
      redirect_to edit_media_entry_path(@media_entry)
    else
      render :action => 'new'
    end
  end
  
  def edit
    @media_entry = MediaEntry.find(params[:id])
  end
  
  def update
    @media_entry = MediaEntry.find(params[:id])
    
    if @media_entry.update_attributes(params[:media_entry])
      flash[:notice] = "This media entry has been saved successfully."
      
      redirect_to edit_media_entry_path(@media_entry)
    else
      render :action => 'edit'
    end
  end
  
  protected
    def load_lookups
      @logos = MediaLogo.all
    end
end
