require 'colorize'
require 'httparty'
require 'nokogiri'
require 'uri'
require 'fileutils'

shapeshifter_logo = <<~LOGO
   ███████╗██╗  ██╗ █████╗ ██████╗ ███████╗███████╗██╗  ██╗██╗███████╗████████╗███████╗██████╗ 
   ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔════╝██╔════╝██║  ██║██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗
   ███████╗███████║███████║██████╔╝█████╗  ███████╗███████║██║███████╗   ██║   █████╗  ██████╔╝
   ╚════██║██╔══██║██╔══██║██╔═══╝ ██╔══╝  ╚════██║██╔══██║██║██╔════╝   ██║   ██╔══╝  ██╔══██╗
   ███████║██║  ██║██║  ██║██║     ███████╗███████║██║  ██║██║██║        ██║   ███████╗██║  ██║
   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝
LOGO

puts shapeshifter_logo.colorize(:light_blue).bold

def is_valid_url?(url)
  uri = URI.parse(url)
  uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
rescue URI::InvalidURIError
  false
end

def get_all_links(url)
  begin
    response = HTTParty.get(url)
    if response.code != 200
      puts "Failed when trying to access #{url}. Code Status: #{response.code}"
      return []
    end

    document = Nokogiri::HTML(response.body)
    links = document.css('a[href]').map { |link| link['href'] }.uniq

    links.map! do |link|
      begin
        full_link = URI.join(url, link).to_s
        full_link if is_valid_url?(full_link)
      rescue URI::InvalidURIError
        nil
      end
    end

    links.compact.uniq.select { |link| URI.parse(link).host == URI.parse(url).host }

  rescue => e
    puts "Error trying to process URL: #{e.message}"
  end
end

def save_html(url, folder_name)
  begin
    # get body from main page
    response = HTTParty.get(url)
    if response.code == 200
      filename = File.join(folder_name, URI.parse(url).path.gsub('/', '_').sub(/^_/, '') + ".html")
      filename = File.join(folder_name, "index.html") if filename == folder_name + ".html"

      File.open(filename, 'w') do |file|
        file.write(response.body)
      end
      puts "#{filename} was saved successfully"
    else
      puts "was not possible to access #{url}. Code status: #{response.code}"
    end
  rescue => e
    puts "Erro trying to save #{url}: #{e.message}"
  end
end

print "URL (ex: https://www.github.com): "
option = gets.chomp
# read url
print "Main URL (ex: https://www.github.com): "
main_url = gets.chomp

# validade url
unless is_valid_url?(main_url)
    puts "Invalid URL."
    return
end

# create folder for saving htmls
folder_name = "html_pages"
FileUtils.mkdir_p(folder_name)

# get all links
puts "Searching for pages..."
links = get_all_links(main_url)

# verify if links is empty or not
if links.empty?
    puts "No pages were found."
    return
end

puts "#{links.size} pages found. Saving HTMLs..."

# save main page html
save_html(main_url, folder_name)

# save all pages html
links.each do |link|
    next unless is_valid_url?(link)
    save_html(link, folder_name)
end