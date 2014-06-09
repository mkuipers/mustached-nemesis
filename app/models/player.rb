# for each character, there should be a subclass of player
# that uses a refinement implementing that character's
# special ability. You have to create that subclass because
# `using` cannot be called from within a method. Blech.
#
# For `method`,  where `method` is subject to being overriden
# by a refinement, `method` should internally call `_method`,
# so that the refinement can use the original behavior without
# changing the API.

class Player
  delegate :max_health, to: :character

  attr_reader :in_play, :health, :brain, :role, :character, :deck, :left, :right, :range_increase, :range_decrease

  def initialize(role, character)
    @role = role
    @character = character
    @range_increase = 0
    @range_decrease = 0
  end

  def play
    dynamite
    return if dead?
    return if jail
    draw_for_turn
    brain.play
    brain.discard if hand.size > hand_limit
  end

  def sheriff?
    role == "sheriff"
  end

  def hand_size
    hand.size
  end

  def target_of(card, targetter)
    return false if barrel(card)
    hit = brain.target_of(card)
    hit!(targetter) if hit
  end

  def barrel(card)
    if card.barrelable?
      return draw!(:barrel).barreled?
    end
    false
  end

  def hit!(hitter=nil)
    health--
    if dead?
      beer
    else
      PlayerKilledEvent.new(self)
    end
  end

  def heal(regained_health)
    regained_health.times do
      health += 1 if health < max_health
    end
  end

  def dead?
    health <= 0
  end

  def dynamite
    dynamite_card = from_play(Card.dynamite)
    if dynamite_card
      if draw!(:dynamite).explode?
        3.times { hit!  }
        discard(dynamite_card)
      else
        in_play.delete(dynamite_card)
        left[1].in_play << dynamite_card
      end
    end
  end

  def jail
    jail_card = from_play(Card.jail)
    if jail_card
      discard(jail_card)
      return true if draw!(:jail).still_in_jail?
    end
    false
  end

  def jailed?
    in_play?(Card.jail)
  end

  def beer_benefit; 1; end

  private
  def from_play(card_type)
    in_play.detect { |card| card.type = card_type }
  end

  def from_hand(card_type)
    hand.detect { |card| card.type = card_type }
  end

  def discard(card)
    deck.discard << card
    in_play.delete(card)
    hand.delete(card)
  end

  def in_range?(card, target_player)
    if card.no_range?
      true
    elsif card.gun_range?
      gun_range >= distance_to(target_player)
    else
      card.range >= distance_to(target_player)
    end
  end

  def gun_range
    in_play.detect { |card| card.gun? }.range
  end

  def distance_to(target_player)
    left_distance = 1
    right_distance = 1
    player = self.left
    while player != target_player
      left_distance += 1
      player = player.left
    end
    player = self.right
    while player != target_player
      right_distance += 1
      player = player.right
    end
    [left_distance, right_distance].min + target_player.range_increase - self.range_decrease
  end

  def play_and_discard(card, target_player:nil, target_card:nil)
    if in_range?(card, target_player)
      card.play(self)
      discard(card)
    else
      raise OutOfRangeException
    end
  end

  def hand_limit
    health
  end

  def draw_for_turn
    2.times { draw }
  end

  def draw
    hand << deck.take(1)
  end

  def draw!(reason=nil)
    deck.draw!
  end
end
