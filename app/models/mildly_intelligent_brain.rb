
## All Brains must be put in the PlayerBrain module to allow them to be picked up by the game initalizer
module PlayerBrain
  ## This is a sample brain to MURDER ALL
  class MildlyIntelligentBrain < Brain

    #The brain is instantiated with it's role.  So that it can be used later in the game
    def initialize(role)
      @role = role
    end

    # you have the option of picking from many cards, pick the best one.
    def pick(number, *cards)
      # binding.pry
      ordered = cards.flatten.map do |card|
        i = card_preference.map { |preference| card.type == preference }.index(true)
        {card: card, index: i}
      end
      ordered.sort_by { |h| h[:index] || 99 }.first(number).map {|h| h[:card] }
    end
    def card_preference
      [Card.wells_fargo_card, Card.stage_coach_card, Card.jail_card, Card.barrel_card,
        Card.beer_card, Card.indians_card, Card.gatling_card, Card.scope_card, Card.mustang_card,
        Card.missed_card, Card.bang_card, Card.revcarbine_card, Card.remington_card, Card.winchester_card,
        Card.volcanic_card, Card.panic_card, Card.cat_balou_card]
    end
    #After instantiation the Game will pass the brain two characters from the characters in the models/characters folder, the choose_character method must return one of the two characters.
    def choose_character(character_1, character_2)
      (character_preference & [character_1, character_2]).first
    end
    def character_preference
      [:PaulRegretPlayer,:JourdonnaisPlayer,:RoseDoolanPlayer,
       :VeraCusterPlayer,:BlackJackPlayer,:BartCassidyPlayer,
       :SidKetchumPlayerTODO,:SlabTheKillerPlayer,:JesseJonesPlayerTODO,
       :LuckyDukePlayer,:SuzyLafayettePlayer,:WillyTheKidPlayer,
       :VultureSamPlayerTODO,:CalamityJanetPlayer,:PedroRamirezPlayerTODO,:KitCarlsonPlayer,
       :ElGringoPlayer,]
    end

    #This method is called on your brain when you are the target of a card that has a bang action (a missable attack). Your brain is given the card that attacked them.  The method should return a card from your hand
    def target_of_bang(card, targette, missed_needed)
      if player.hand.count{ |x| x.type == Card.missed_card } >= missed_needed
        player.hand.select{|x| x.type == Card.missed_card}.first(missed_needed)
      else
        []
      end
    end
    def target_of_indians(card, targetter)
      player.from_hand(Card.bang_card)
    end
    def target_of_duel(card, targetter)
      player.from_hand(Card.bang_card)
    end

    #This method is called if your hand is over the hand limit, it returns the card that you would like to discard.
    # Returning nil or a card you don't have is a very bad idea. Bad things will happen to you.
    def discard
      non_damage_dealing = player.hand.find {|card| !card.damage_dealing? }
      non_damage_dealing || player.hand.first
    end

    #This is the method that is called on your turn.
    def play
      bangs_played = 0
      while !player.hand.find_all(&:draws_cards?).empty?
        player.hand.find_all(&:draws_cards?).each {|card| player.play_card(card)}
      end
      player.hand.find_all(&:equipment?).each do |card|
        target = weakest_player_in_range_of(card)
        player.play_card(card, target)
      end
      player.hand.find_all(&:damage_dealing?).each do |card|
        is_a_bang_card = card.type == Card.bang_card
        bangs_played += 1 if is_a_bang_card
        if !is_a_bang_card || bangs_played < 1
          target = weakest_player_in_range_of(card)
          player.play_card(card, target) if target
        end
      end
    end

    private
    attr_reader :role

    def weakest_player_in_range_of(card)
      in_range = player.players_in_range_of(card)
      in_range.min_by { |p| p.health } || in_range.first
    end
  end
end