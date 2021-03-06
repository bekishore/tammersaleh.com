---
date: 2010-01-14 12:00 PDT
title: RESTful Google Sitemaps for Rails
---

![Image](old-world-map/large.jpg)
{:.img_right}

I recently added a google sitemap to [tammersaleh.com](http://tammersaleh.com).  I followed [Ilya Grigorik's great instructions](http://www.igvita.com/2006/11/24/google-yahoo-sitemaps-in-rails/), and while they worked peachily, they were a tad bit outdated (2006).  

So here's an updated version that shows how I implemented a RESTful sitemap for my home on the web.

Let's start out with the functional tests, as that is how we roll.

~~~ ruby
# test/functional/sitemaps_controller_test.rb
require File.dirname(__FILE__) + '/../test_helper'
 
class SitemapsControllerTest < ActionController::TestCase
  as_a_visitor do
    context "when there are posts" do
      setup do
        Factory(:post, :published => true)
        Factory(:post, :published => true)
      end
 
      context "on get to show" do
        setup { get :show, :format => "xml" }
        should_render_template :show
        should_assign_to :posts
        should_assign_to :pages
      end
    end
  end
end
~~~

The `as_a_visitor` context just ensures there's nobody logged in.  Now, let's knock the Controller and View layers out.  Starting with the routes:

~~~ ruby
# config/routes.rb
map.resource :sitemap
~~~

...moving on to the controller...

~~~ ruby
# app/controllers/sitemaps_controller.rb
class SitemapsController < ApplicationController
  # Be sure to skip any authentication filters you have.
  skip_before_filter :require_user
 
  def show
    # These are static pages, not AR models.
    @pages = [
      { :title => "Hire me.",  :url => "/hire"     },
      { :title => "About me.", :url => "/about"    },
      { :title => "Speaking.", :url => "/speaking" },
    ]
    # You don't have to limit the fields, but it's not a bad idea for performance.
    @posts = Post.ordered.published.all(:select => 'id, slug, title, created_at')
  end
end
~~~

...the view...

~~~ ruby
# app/views/sitemaps/show.xml.builder
xml.instruct!
 
xml.urlset "xmlns" => "http://www.google.com/schemas/sitemap/0.84" do
  xml.url do
    xml.loc "http://#{request.host}/"
    xml.lastmod Time.now.to_s(:w3c)
    xml.changefreq "always"
  end
 
  @pages.each do |page|
    xml.url do
      xml.loc "http://#{request.host}#{page[:url]}"
      xml.lastmod Time.now.to_s(:w3c)
      xml.changefreq "daily"
      xml.priority 0.9
    end
  end

  @posts.each do |post|
    xml.url do
      xml.loc post_url(post)
      xml.lastmod post.created_at.to_s(:w3c)
      xml.changefreq "weekly"
      xml.priority 0.6
    end
  end
end
~~~

...and a little time extension sugar...

~~~ ruby
# config/initializers/time_formats.rb
Time::DATE_FORMATS[:w3c] = lambda {|time| time.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00") }
~~~

Dead simple, and nicely RESTful.  After you deploy these changes, you can manually test your sitemap using curl:

~~~
# curl -is http://tammersaleh.com/sitemap.xml 

HTTP/1.1 200 OK
Content-Type: application/xml; charset=utf-8
...

<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.google.com/schemas/sitemap/0.84">
  <url>
    <loc>http://tammersaleh.com/</loc>
    <lastmod>2010-01-14T18:13:21+00:00</lastmod>
    <changefreq>always</changefreq>
  </url>
  <url>
    <loc>http://tammersaleh.com/hire</loc>
    <lastmod>2010-01-14T18:13:21+00:00</lastmod>
    <changefreq>daily</changefreq>
    <priority>0.9</priority>
  </url>
  <url>
    <loc>http://tammersaleh.com/about</loc>
    <lastmod>2010-01-14T18:13:21+00:00</lastmod>
    <changefreq>daily</changefreq>
...
~~~

### Telling Google

![Image](Webmaster_Tools_-_Sitemaps/large.jpg)
{:.img_left}

The final step is to register your sitemap with the [google webmaster tools](https://www.google.com/webmasters/tools) site.  Create a new site, and follow the **Sitemaps** link under the **Site configuration** menu item.  The sitemap path is `/sitemap.xml`.
