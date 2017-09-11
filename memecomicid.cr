require "db"
require "sqlite3"
require "modest"
require "myhtml"
require "http/client"

Data = DB.open "sqlite3://./memebot.db"

(0...300).each do |i|
  getMeme(i)
end

def getMeme(i)
  a = HTTP::Client.get("https://www.memecomic.id/async/all?page=#{i}", headers: HTTP::Headers{"X-Requested-With" => "XMLHttpRequest"})
  if a.success?
    b = a.body
    c = Myhtml::Parser.new(b)
    puts c
    images = c.css(".mci-postimg img").map(&.attribute_by("src")).to_a
    title = c.css(".mci-poststatus span").map(&.inner_text).to_a
    ids = c.css(".mci-post").map(&.attribute_by("id")).to_a
    (0...images.size).each do |i|
      id = ids[i]
      img = images[i].to_s
      check = Data.query_one? "select title from main_posts where ukey=? limit 1", id, as:{String}
      if !check && img != "https://www.memecomic.id/media/ifyouknow.jpg"
        t = title[i]
        puts "[INSERT] #{t} - #{Time.now}"
        date = Time.now.epoch
        li = img.split("/").last.to_s + Time.now.epoch.to_s + ".jpg"
        d = HTTP::Client.get img
        d.success? ? downloadImage(li, d.body) : puts "Fail save image"
        Data.exec "insert into main_posts (title,image,date,ukey,localimage) values (?,?,?,?,?)", t, img, date, id, li
        Data.close
      end
    end
  end
end

def downloadImage(name, file)
  File.write("images/" + name, file)
end
