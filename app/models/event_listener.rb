class EventListener
  attr_reader :game, :subscribers

  def initialize(game, logger)
    @game = game
    @subscribers = []
    @logger = logger
  end

  def subscribe(subscriber)
    subscribers << subscriber
  end

  def notify(event)
    @logger.info(event.to_s)
    if event.player_killed?
      if event.killed.sheriff? || sheriff_win?
        GameOverEvent.new(self, event, game) #TODO double renegades
      end
    end
    subscribers.each {|sub| sub.notify(event)}
  end

  def sheriff_win?
    living_players = game.living_players
    roles = living_players.map(&:role)
    !(roles.include?('outlaw') || roles.include?('renegade'))
  end
end

class GameOverEvent < Event
  attr_reader :player_killed_event, :game, :winners
  def initialize(event_listener, player_killed_event, game)
    @player_killed_event = player_killed_event
    @game = game
    winner
    super(event_listener)
  end

  def winner
    living_players = game.living_players
    @winners = []
    if living_players.find { |p| p.sheriff?}
      @winners = game.players.find_all { |player| ['deputy', 'sheriff'].include?(player.role)}.uniq
      'the forces of law have'
    elsif living_players.map(&:role) == ['renegade']
      @winners = living_players
      'the renegade has'
    else
      @winners = game.players.find_all { |player| player.role == 'outlaw'}.uniq
      'the outlaws have'
    end
  end

  def to_s
    "#{winner} prevailed in #{game.round} rounds!\n The following people are still alive: #{game.living_players.map(&:to_s)}"
  end
  def game_over?; true; end
end
