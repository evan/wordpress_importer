#!/usr/bin/env ruby

require "fileutils"
require "erb"
require "time"

header = ERB.new(File.read("header.erb"))
post = ERB.new(File.read("post.erb"))
comment = ERB.new(File.read("comment.erb"))

@header_contents = ""
@post_id = 0
FileUtils.chdir("import") do	
	Dir["**/intro.element"].sort.each do |path|
	  begin
		  url = path.split("/")
		  @post_id += 1
		  @post_short_link = url[-2]
		  @post_date = url[0..2].join("/")
		  @post_link = "http://blog.evanweaver.com/" + @post_date + "/" + @post_short_link + "/"
		  @post_date_gmt = Time.parse(@post_date).strftime("%Y-%m-%d %H:%M")
		  @post_excerpt = File.read(path)
		  @post_title = File.read(path.sub("intro", "title"))
		  @post_contents = @post_excerpt + File.read(path.sub("intro", "body"))
		  @post_excerpt = nil if @post_contents == @post_excerpt
		  @post_comments = ""
		  @comment_id = 0
		  
		  Dir["#{@post_date}/#{@post_short_link}/comments/**/body.element"].sort.each do |path|
		    @comment_id += 1
		    author = File.read(path.sub("body", "author"))
		    if author =~ /href="(.*?)" rel="nofollow">(.*?)</
	  		  @comment_author = $2
			    @comment_author_url = $1
			else
				@comment_author = author
			end
			
		    @comment_date_gmt = Time.parse(File.read(path.sub("body", "date"))).strftime("%Y-%m-%d %H:%M")
		    @comment_content = File.read(path)
		    
		    @post_comments << comment.result(binding)
		  end
		  
		  @header_contents << post.result(binding)
      rescue Errno::ENOENT
      end
	end
end
	
puts header.result(binding)