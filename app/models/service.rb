class Service
  attr_accessor :path, :config, :data

  def initialize(path:, config:, data:)
    @path = path
    @config = config
    @data = data
  end

  def pages
    @pages ||= Dir.glob("#{path}/metadata/page/*.json").map do |page_path|
      Page.new(path: page_path, config: config, service: self)
    end
  end

  def start_page
    pages.find { |p| p.start? }
  end

  def find_page_for_url(url)
    pages.find { |page| page.url == url }
  end

  def find_page_by_id(id)
    pages.find { |page| page.id == id }
  end
end
