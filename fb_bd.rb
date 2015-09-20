require 'net/https'
require 'uri'
require 'json'
require 'date'


#put your access_token below
ACCESS_TOKEN= 'acess_token'			#eg: 'ADSD124512C' (will be very long)

#change the max limit of the comments to be fetched
LIMIT =200							

#Enter your BDATE here in YYYY,MM,DD format. Converted to UTC UNIX time which FB graph api uses
BDATE = Date.new(2015,9,20).to_time.utc.to_i.to_s		

#Array of words that will be check in the wall_post to count it as a Birthday Wish
BDAY_WISHES = ['hbd','happy','birthday','returns','bday','hb','b\'day','wish']

#Array of replies one of which will be randomly chosen comment on the post
WISH_REPLY = ['Ty :)','Thanks','Thank you :)','thanks','ty','thanx','thank you so much :D']

GRAPH_API_URL = 'https://graph.facebook.com/'


ACCESS_TOKEN_PART= 'access_token=' + ACCESS_TOKEN

liked_count = 0
commented_count = 0

uri = URI.parse(GRAPH_API_URL)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl=true

#retrieve request with id,status_type etc fields and will fetch data since the above BDATE (Max LIMIT posts)
#'date_format=U' retrieves the date format in UTC Unix Time
request = Net::HTTP::Get.new('/me/feed?fields=id,status_type,message,type,created_time&since='+BDATE+'&limit=' + LIMIT.to_s+ '&date_format=U&'+ACCESS_TOKEN_PART)

#get the api response
response = http.request(request)

#check for errors in http response
case response.code.to_i
	when 200 || 201
	  	puts "Request Successful"
	when (400..499)
		abort "Invalid/Bad Request. Exiting"
	when (500..599)
	  	abort "Server Problems. Exiting"
end

#parse the JSON object
res=JSON.parse(response.body)

#get 'data' from it
posts=res['data']

for post in posts
	
	#getting the message content of the post
	wish=post['message'].downcase
	
	#if any of the words in BDAY_WISHES array is present in the message then like/comment on it
	if BDAY_WISHES.any? {|w| wish.include?w}
		
		post_link = GRAPH_API_URL + post['id']
		
		#to like a post,just POST on the 'post_id/likes' URL with the access_token
		like_url=post_link + '/likes'
		like_params = {access_token: ACCESS_TOKEN}
		like_response = Net::HTTP.post_form(URI(like_url),like_params)
		
		#quirks_mode required here because API returns just a boolean fragment like '{"success": true}'	
		like_res=JSON.parse(like_response.body,:quirks_mode => true)
		if like_res == true
			liked_count += 1				
		end
		

		#to comment on a post,just POST on the 'post_id/comments' URL with the access_token and message
		comment_url = post_link + '/comments'
		comment_params = {access_token: ACCESS_TOKEN,message: WISH_REPLY.sample}		
		comment_response = Net::HTTP.post_form(URI(comment_url),comment_params)

		#quirks_mode required here because API returns just a boolean fragment like '{"success": true}'
		comment_res=JSON.parse(comment_response.body,:quirks_mode => true)

		if comment_res['id']
			commented_count += 1
		end
		
	end

end

puts "Total Posts Receieved #{posts.length}"
puts "Total Posts Liked #{liked_count}"
puts "Total Posts Commented #{commented_count}"


