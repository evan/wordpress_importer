#!/usr/bin/env ruby

require "rubygems"
require "fileutils"
require "erb"
require "time"
require "nokogiri"
require "ruby-debug"

GMT_OFFSET =  60*60*8
DATE_FORMAT = "%Y-%m-%d %H:%M"

header = ERB.new(File.read("header.erb"))
post = ERB.new(File.read("post.erb"))
comment = ERB.new(File.read("comment.erb"))

def fix_newlines(string)
  doc = Nokogiri::HTML::DocumentFragment.parse(string)
  doc.css("p").each do |p|
    p.content = p.content.gsub("\n", " ")
  end
  doc.to_html.gsub("<p></p>", "")
end

@header_contents = ""
@post_id = 0
FileUtils.chdir("import") do
  Dir["**/intro.element"].sort.each do |path|
    begin
      url = path.split("/")
      @post_id += 1
      @post_short_link = url[-2]
      @post_date_path = url[0..2].join("/")
      @post_link = "http://blog.evanweaver.com/" + @post_date_path + "/" + @post_short_link + "/"
      date = Time.parse(@post_date_path)
      @post_date = date.strftime(DATE_FORMAT)
      @post_date_gmt = (date + GMT_OFFSET).strftime(DATE_FORMAT)
      @post_title = File.read(path.sub("intro.el", "title.el"))
      @post_contents = fix_newlines(File.read(path) + File.read(path.sub("intro.el", "body.el")))
      @post_comments = ""
      @comment_id = 0

      Dir["#{@post_date_path}/#{@post_short_link}/comments/**/body.element"].sort.each do |path|
        @comment_id += 1
        author = File.read(path.sub("body.el", "author.el"))
        if author =~ /href="(.*?)" rel="nofollow">(.*?)</
          @comment_author = $2
          @comment_author_url = $1
        else
          @comment_author = author
        end
        
        date = Time.parse(File.read(path.sub("body.el", "date.el")))
        @comment_date = date.strftime(DATE_FORMAT)
        @comment_date_gmt = (date + GMT_OFFSET).strftime(DATE_FORMAT)
        @comment_content = fix_newlines(File.read(path).gsub("<p></p>", ""))

        @post_comments << comment.result(binding)
      end

      @header_contents << post.result(binding)
    end
  end
end

puts header.result(binding)
