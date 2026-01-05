require 'nokogiri'

module Jekyll
  class LightboxProcessor
    # Process HTML content to add lightbox attributes to images
    def self.process(content, page_id, site_config = {})
      return content if content.nil? || content.empty?
      
      # Check if lightbox is enabled in configuration
      lightbox_config = site_config['lightbox'] || {}
      return content unless lightbox_config['enabled'] != false
      
      # Parse HTML content
      doc = Nokogiri::HTML::DocumentFragment.parse(content)
      
      # Find all image tags
      images = doc.css('img')
      
      return content if images.empty?
      
      # Process each image with the appropriate group ID based on gallery mode
      gallery_mode = lightbox_config['gallery_mode'] || 'per_post'
      group_id = generate_group_id(page_id, gallery_mode)
      
      images.each_with_index do |img, index|
        process_image(img, group_id, index)
      end
      
      # Return the modified HTML
      doc.to_html
    end
    
    private
    
    # Process individual image element
    def self.process_image(img, group_id, index)
      # Skip if image is already wrapped in a lightbox link
      parent = img.parent
      return if parent && parent.name == 'a' && parent['data-lightbox']
      
      # Get the image's src for the lightbox link
      img_src = img['src']
      return unless img_src
      
      # Prepare data attributes for the link
      data_attrs = {
        'data-lightbox' => group_id
      }
      
      # Map alt text to data-title if alt exists
      if img['alt'] && !img['alt'].empty?
        data_attrs['data-title'] = img['alt']
      elsif img['title'] && !img['title'].empty?
        data_attrs['data-title'] = img['title']
      end
      
      # Check if image is already wrapped in a link
      if parent && parent.name == 'a'
        # Add lightbox attributes to existing link
        data_attrs.each { |key, value| parent[key] = value }
        # Update href to point to full-size image
        parent['href'] = img_src
      else
        # Create new link wrapper
        link = Nokogiri::XML::Node.new('a', img.document)
        link['href'] = img_src
        data_attrs.each { |key, value| link[key] = value }
        
        # Replace image with link containing the image
        img.add_previous_sibling(link)
        img.remove
        link.add_child(img)
      end
    end
    
    # Generate unique group identifier based on gallery mode
    def self.generate_group_id(page_id, gallery_mode)
      case gallery_mode
      when 'per_page'
        # Each page gets its own gallery group
        clean_id = page_id.to_s.gsub(/[^a-zA-Z0-9\-_]/, '-').gsub(/-+/, '-')
        clean_id = clean_id.gsub(/^-+|-+$/, '') # Remove leading/trailing dashes
        "gallery-#{clean_id}"
      when 'global'
        # All images across the site share the same gallery
        'gallery-global'
      else # 'per_post' (default)
        # Each post gets its own gallery group (original behavior)
        clean_id = page_id.to_s.gsub(/[^a-zA-Z0-9\-_]/, '-').gsub(/-+/, '-')
        clean_id = clean_id.gsub(/^-+|-+$/, '') # Remove leading/trailing dashes
        "gallery-#{clean_id}"
      end
    end
  end
  
  # Hook into Jekyll's post-processing for posts
  Jekyll::Hooks.register :posts, :post_render do |post|
    # Use post slug or id for grouping
    post_id = post.data['slug'] || post.id
    post.output = LightboxProcessor.process(post.output, post_id, post.site.config)
  end
  
  # Also process pages
  Jekyll::Hooks.register :pages, :post_render do |page|
    # Generate a simple ID for pages based on URL
    page_id = page.url.gsub('/', '-').gsub('.html', '').gsub(/^-+|-+$/, '')
    page_id = 'index' if page_id.empty?
    page.output = LightboxProcessor.process(page.output, page_id, page.site.config)
  end
end