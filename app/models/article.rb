require 'open-uri'

class Article < ActiveRecord::Base
  serialize :top_keywords, Hash
  serialize :links, Array

  def self.analyze(url)
    doc = Nokogiri::HTML(open(url))
    article = Article.new(url: url)
    article.set_domain(url)
    article.set_content(doc)
    article.set_keywords
    article.set_author(doc)
    article.set_publisher(doc)
    article.set_published_date(doc)
    article.set_links(doc)
    article.save
    article
  end

  def set_domain(url)
    self.domain = (URI.parse url).host
  end

  # Grab all the inner text of the body.  Refine this later
  def set_content(doc)
    doc.css('script').remove
    self.content = doc.css("body").inner_text
  end

  def set_links(doc)
    _links = doc.css("body a")
    _links.each do |link|
      value = link.attributes["href"].value
      next if value.match(/^\/|#/)
      next if value.match(".*#{self.domain}.*")
      self.links.push link.attributes["href"].value
    end
  end

  def set_published_date(doc)
    if doc.css("meta[itemprop=datePublished]")[0].present?
      date_time = doc.css("meta[itemprop=datePublished]")[0].attributes['content'].value
      self.published_date = Time.parse(date_time)
    end
  end
  def set_keywords
    words = self.content.scan(/\w{4,}+/)
    keywords = Hash[
      words.group_by(&:downcase).map{ |word,instances|
        [word,instances.length]
      }.sort_by(&:last).reverse
    ]
    self.top_keywords = keywords.first(20).to_h
  end

  def set_author(doc)
    if doc.css("head meta[name=author]")[0].present?
      self.author_name = doc.css("head meta[name=author]")[0].attributes['content'].value
    elsif doc.css('.author').present?
      self.author_name = doc.css('.author').inner_html
    end
  end

  def set_publisher(doc)
    if doc.css("head meta[property='og:site_name']")[0].present?
      self.publisher_name = doc.css("head meta[property='og:site_name']")[0].attributes['content'].value
    else
      self.publisher_name = self.domain
    end
  end

  def domain_ruburic
    bad_site = Website.where(domain: self.domain)
    if bad_site.present?
      {'fail' => bad_site[0].tag }
    else
      {'pass' => "not blacklisted" }
    end
  end

  def blog_ruburic
    if url.match(/blog|wordpress/).present?
      {'fail' => 'blog or wordpress site' }
    else
      {'pass' => "blog not detected" }
    end
  end

  def obscenity_ruburic
    bad_words = Obscenity.offensive(self.content)
    if bad_words.present?
      {'fail' => bad_words}
    else
      {'pass' => 'no obscenity'}
    end
  end

  def breaking_news_ruburic
    if self.published_date.present?
      if self.published_date < 1.days.ago
        {'warning' => 'recently published, breaking news'}
      elsif published_date > 10.years.ago
        {'warning' => 'over 10 years old, possibly outdated'}
      else
        {'pass' => "published on #{self.published_date}"}
      end
    else
      {'unknown' => 'no published date detected'}
    end
  end

  def social_mentions
    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "IFv31pwbFKnzfCRrTweSEaSnI"
      config.consumer_secret     = "6vtAbSdRrkaprHX3vq2esKthrWO7vj5VOsxRFG0PglJ1EMXoYA"
      config.access_token        = "292649798-AVn0ihYH9h1b2bkPIwOsvct28ZCFEi8gSu06P4WT"
      config.access_token_secret = "wC4Zc49I2GStG3zew7xAyZ35dHxFe21BvkNpFqk0l9P5y"
    end
    mentions = twitter_client.search("#{self.url} -rt")
    {
      "twitter_mentions" => mentions.count,
      "sample" => mentions.take(10).map{|x| x.text}
    }
  end

  def get_quotes
    self.content.scan(/"([^"]*)"/)
  end

  def about_page
    begin
      about_page = Nokogiri::HTML(open('http://' + self.domain + '/about'))
      about_page.css('script').remove
      about_content = about_page.css('body').inner_text
    rescue
    end
    if about_content.present?
      about_content
    else
      ''
    end
  end
end
