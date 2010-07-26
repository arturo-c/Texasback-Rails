class SiteController < ApplicationController
  session :off
  skip_before_filter :verify_authenticity_token
  
  no_login_required
  
  attr_accessor :config, :cache
  
  caches_page :appointments
  
  def initialize
    @config = Radiant::Config
    @cache = ResponseCache.instance
  end
  
  def show_page
    response.headers.delete('Cache-Control')
    
    url = params[:url]
    if Array === url
      url = url.join('/').downcase
    else
      url = url.to_s.downcase
    end
    
    if (request.get? || request.head?) and live? and (@cache.response_cached?(url))
      @cache.update_response(url, response, request)
      @performed_render = true
    else
      show_uncached_page(url)
    end
  end
  
  def appointments
    @page = Page.find_by_url('/appointments', true)
    
    @content_for_header_content = header_content_for_page('appointments')
    @content_for_body_class = body_class_for_page('appointments')
    @content_for_title_tag = title_tag_for_page('appointments')
    
    @radiant_layout = "Default Layout"
    
    render :layout => 'radiant'
  end
  
  private
    
    def find_page(url)
      found = Page.find_by_url(url, live?)
      found if found and (found.published? or dev?)
    end

    def process_page(page)
      page.process(request, response)
    end
    
    def show_uncached_page(url)
      @page = find_page(url)
      unless @page.nil?
        process_page(@page)
        @cache.cache_response(url, response) if request.get? and live? and @page.cache?
        @performed_render = true
      else
        render :template => 'site/not_found', :status => 404
      end
    rescue Page::MissingRootPageError
      redirect_to welcome_url
    end

    def dev?
      if dev_host = @config['dev.host']
        request.host == dev_host
      else
        request.host =~ /^dev\./
      end
    end
    
    def live?
      not dev?
    end

end
