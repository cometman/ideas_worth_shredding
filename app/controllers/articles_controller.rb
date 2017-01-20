class ArticlesController < ApplicationController
  def index
    @articles = Article.all
    render json: @articles
  end

  def analyze
    url = params[:url]
    @article = Article.analyze(url)
    result_json = @article.as_json
    # byebug
    result_json["about_page"] = @article.about_page
    result_json["quotes"] = @article.get_quotes
    result_json["social_mentions"] = @article.social_mentions
    result_json["domain_ruburic"] = @article.domain_ruburic
    result_json["blog_ruburic"] = @article.blog_ruburic
    result_json["obscenity_ruburic"] = @article.obscenity_ruburic
    result_json["breaking_new_ruburic"] = @article.breaking_news_ruburic

    render json: result_json
  end
end
