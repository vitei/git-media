require 'git-media/status'
require 'digest'

module GitMedia
  module Check

    def self.run!
      @pull = GitMedia.get_pull_transport
      self.check_local_cache
    end
    
    def self.check_local_cache
     	puts "Checking local media cache.."
	media_buffer = GitMedia.get_media_buffer
      	all_cache = Dir.chdir(media_buffer) { Dir.glob('*/*') }
      	
	all_cache.each do |file|

        	media_file = File.join(media_buffer,file)
		infile = File.open(media_file, 'rb')

		hashfunc = Digest::SHA1.new

        	while data = infile.read(4096)
          		hashfunc.update(data)
        	end

		infile.close()

		sha = file[3..-1]
 
		if sha != hashfunc.hexdigest then
			print "Pulling corrupt file "+sha+" ..."
			@pull.pull(nil,sha)
			print " Done\n"
		end

	end
	

	#unpushed_files = @push.get_unpushed(all_cache)
      #pushed_files = all_cache - unpushed_files
      #pushed_files.each do |sha|
      #  puts "removing " + sha[0, 8]
      #  File.unlink(File.join(GitMedia.get_media_buffer, sha))
      #end
    end
    
  end
end
