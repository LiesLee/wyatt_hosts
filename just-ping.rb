require 'bundler'
Bundler.require

# Thanks for  
#  hostsx https://code.google.com/p/hostsx/  
#  MVPS http://winhelp2002.mvps.org/ 
#  huhamhire-hosts https://code.google.com/p/huhamhire-hosts/
#  smarthosts https://code.google.com/p/smarthosts/
#  google-hosts https://github.com/txthinking/google-hosts

puts "According to right now pc Location to find domain ip:"

puts "Need Block Ads? (y/n)"
ads = gets.strip == 'y'

puts "Need Ads!" if ads

# 解析要抓取的网站
SITES = open('./sites').read.strip.lines.to_a.map { |l| l.strip }.select { |line| !line.index('#') }

# 最终的 IP 地址
IPS = {}

def just_ping(site)
  # 注意, 需要当前的 PC 的网络进入 VPN 后才会最有效, 不然在本地被防火墙给重置了 dns 就无法处理了
  cmd = "dig #{site} -4 +short +tcp @8.8.8.8"
  result = `#{cmd}`
  result.split("\n").select { |ip| ip =~ /^\d{2,3}/}.first
end

SITES.map do |site|
        sleep(0.02)
	Thread.new do
		begin
			puts "#{Thread.current} begin..."
			IPS[site] = just_ping site.strip
			puts "#{Thread.current} end..."
		rescue Exception => e
			puts "#{e.message} #{site}"
			IPS[site] = ''
		end
	end
end.each(&:join)

base_template = open('template/base_template.ini').read
google_template = open('template/google_template.ini').read
apple_template = open('template/apple_template.ini').read
alibaba_template = open('template/alibaba_template.ini').read

# 组织广告
mvps_tempalte = ads ? HTTParty.get('http://winhelp2002.mvps.org/hosts.txt', headers: {'Accept-Encoding' => 'gzip'}).body.strip : ""

IPS.each do |k, v|
	next if v == ''
	# google
	if k.include?('g.cn')
		google_template = google_template.gsub(/\$\{1\}/, v)
		google_template = google_template.gsub(/\$\{2\}/, v)
		google_template = google_template.gsub(/\$\{4\}/, v)
		google_template = google_template.gsub(/\$\{5\}/, v)
	elsif k.include?('gstatic')
		google_template = google_template.gsub(/\$\{3\}/, v)
	# apple
	elsif k.include?('icloud')
		apple_template = apple_template.gsub(/\$\{1\}/, v)
	elsif k.include?('swcdn')
		apple_template = apple_template.gsub(/\$\{2\}/, v)
	elsif k.include?('mzstatic')
		apple_template = apple_template.gsub(/\$\{3\}/, v)
	elsif k.include?('phobos')
        # 219.76.10.14 fastest
		# 203.69.113.136 taiwan
		apple_template = apple_template.gsub(/\$\{4\}/, v)
	elsif k.include?('edgekey')
		apple_template = apple_template.gsub(/\$\{5\}/, v)
	elsif k.include?('metrics')
		apple_template = apple_template.gsub(/\$\{6\}/, v)
	# alibaba
	elsif k.include?('aliimg')
		alibaba_template = alibaba_template.gsub(/\$\{1\}/, v)
	# amazon
	else
		base_template << "#{v}	#{k}\n"
	end
	puts "#{k}		#{v}"
end

all_in_one = base_template << "\n" << google_template << "\n" << apple_template << "\n" << alibaba_template << "\n" << "\n\n" << mvps_tempalte
open("hosts.#{Time.now.to_i}.txt", 'w') { |io| io.write(all_in_one) }
