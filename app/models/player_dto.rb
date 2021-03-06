class PlayerDTO
  attr_reader :name, :health, :max_health, :in_play, :hand_size, :range_increase,
    :range_decrease, :distance_to, :sheriff
  def initialize(player, for_player)
    @name = player.class
    @health = player.health
    @max_health = player.max_health
    @in_play = player.in_play.map(&:class)
    @hand_size = player.hand_size
    @range_increase = player.range_increase
    @range_decrease = player.range_decrease
    @distance_to = for_player.distance_to(player)
    @sheriff = player.sheriff?
  end

  alias_method :sheriff?, :sheriff
end
