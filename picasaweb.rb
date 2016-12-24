require "nokogiri"

module PicasaWeb
  def self.list_albums(token, user="default")
    Nokogiri::XML(token.get("https://picasaweb.google.com/data/feed/api/user/#{user}").body) do |config|
      config.strict
    end.xpath("/xmlns:feed/xmlns:entry").map do |node|
      Album.new(node)
    end
  end

  def self.list_photos(token, album, user="default")
    Nokogiri::XML(token.get("https://picasaweb.google.com/data/feed/api/user/#{user}/albumid/#{album}/").body) do |config|
      config.strict
    end.xpath("/xmlns:feed/xmlns:entry").map do |node|
      begin
        Photo.new(node)
      rescue => e
        puts "could not import photo: " + e
        next nil
      end
    end.compact
  end

  def self.get_photo(token, albumID, photoID, user="default")
    doc = Nokogiri::XML(token.get("https://picasaweb.google.com/data/feed/api/user/#{user}/albumid/#{albumID}/photoid/#{photoID}").body) do |config|
      config.strict
    end
    Photo.new(doc.at_xpath("/xmlns:feed"))
  end
  
  class Album
    def initialize(node)
      @id = node.at_xpath("./gphoto:id").content.to_i
      @user = node.at_xpath("./gphoto:user").content.to_i
      @title = node.at_xpath("./xmlns:title").content
      @numphotos = node.at_xpath("./gphoto:numphotos").content.to_i
      @access = node.at_xpath("./gphoto:access").content
      #@album_type = node.at_xpath("./gphoto:albumType").content
    end
    
    attr_reader :id
    attr_reader :user
    attr_reader :title
    attr_reader :numphotos
    attr_reader :access
    attr_reader :album_type
  end

  class Photo
    def initialize(node)
      @title = node.at_xpath("./xmlns:title").content
      #@content_url = node.at_xpath("./xmlns:content/@src").content
      @id = node.at_xpath("./gphoto:id").content.to_i
      @albumid = node.at_xpath("./gphoto:albumid").content.to_i
      @access = node.at_xpath("./gphoto:access").content
      @width = node.at_xpath("./gphoto:width").content.to_i
      @height = node.at_xpath("./gphoto:height").content.to_i
      @size = node.at_xpath("./gphoto:size").content.to_i
      mg = node.at_xpath("./media:group")
      @fullsize = mg.xpath("./media:content").map do |mc|
        MediaImage.new(mc, :content)
      end.max { |a,b| a.width <=> b.width}
      @thumbnails = mg.xpath("./media:thumbnail").map do |mt|
        MediaImage.new(mt, :thumbnail)
      end
    end

    class MediaImage
      def initialize(tag, type)
        @url = tag.at_xpath("./@url").content
        @width = tag.at_xpath("./@width").content.to_i
        @height = tag.at_xpath("./@height").content.to_i
        medium = tag.at_xpath("./@medium")
        @medium = medium ? medium.content : "image"
        @type = type
      end

      attr_reader :url
      attr_reader :width
      attr_reader :height
      attr_reader :medium
      attr_reader :type
    end

    attr_reader :title
    #attr_reader :content_url
    attr_reader :id
    attr_reader :albumid
    attr_reader :access
    attr_reader :width
    attr_reader :height
    attr_reader :size
    attr_reader :fullsize
    attr_reader :thumbnails
  end
end
