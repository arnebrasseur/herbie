require 'yaml'

require 'herbie/player'
require 'herbie/ui'
require 'herbie/model/playlist'
require 'herbie/model/browser'
require 'herbie/controller/playlist_controller'
require 'herbie/controller/browser_controller'
require 'herbie/lastfm'

LOG = File.open('/tmp/herbie.log','a')

def log(msg); LOG << "[%s] %s\n" % [Time.now.strftime("%Y-%m-%d %H:%M:%S"), msg] ; LOG.flush end

module Herbie

  class Herbie
    CONFIG = YAML.load(IO.read(File.join(ENV['HOME'], '.herbie'))) rescue {}

    def initialize
      @player = Player.new
      @ui = UI.new
      @browser = Browser.new
      @playlist = Playlist.new
      @lastfm = Scrobbler.new(@player, @ui)

      @playlist_controller = PlaylistController.new(@ui, @playlist, @player)
      @browser_controller = BrowserController.new(@ui, @playlist, @browser)

      @ui.watch.keypress do |pos, key|
        if key == ?q || key == ?Q
          @player.quit
          false
        end
        true
      end
      @playlist_controller.update_ui_playlist
    end

    def loop
      t = Thread.new {@ui.loop},
      @player.loop
      t.join
    end
  end
end

