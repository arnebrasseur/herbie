module Herbie
  class Scrobbler
    attr_reader :config, :lastfm

    def initialize(player, ui)
      begin
        require 'lastfm'
        require 'taglib'

        @config = Herbie::CONFIG['lastfm']
        exit unless config && config['api_key'] && config['api_secret']

        @lastfm = Lastfm.new(config['api_key'], config['api_secret'])
        
        unless config['session']
          token = lastfm.auth.get_token
          puts "Please visit http://www.last.fm/api/auth/?api_key=%s&token=%s and approve Herbie, then press any key to continue." % [config['api_key'], token]
          STDIN.getc
          lastfm.session = config['session'] = lastfm.auth.get_session(token)
          Herbie.save_config
        else
          lastfm.session = config['session']
        end

        @file = nil

        player.watch do |watch|
          watch.playfile do |file|
            @file = file
            tag_file = TagLib::MPEG::File.new(file)
            tags = tag_file.id3v2_tag
            
            if tags
              @lastfm.track.update_now_playing(tags.artist, tags.title)
            end
          end

          watch.end_of_stream do |msg|
            tag_file = TagLib::MPEG::File.new(@file)
            tags = tag_file.id3v2_tag
            
            if tags
              @lastfm.track.scrobble(tags.artist, tags.title)
              ui.set_status(:bottom, "scrobbled [%s - %s]" % [tags.artist, tags.title])
            end            
          end
        end

      rescue LoadError => e
        puts e
        exit
      end
    end

  end
end
