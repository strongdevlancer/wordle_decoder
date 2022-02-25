# frozen_string_literal: true

class WordleDecoder
  class WordGuess
    def initialize(hint_line, answer_chars)
      @letter_guesses = initialize_letter_guesses(hint_line, answer_chars)
    end

    attr_reader :letter_guesses

    def guessable_words
      @guessable_words ||= compute_guessable_words
    end

    BASE_INCONFIDENCE = 0.05

    def confidence_score
      score = (100 * (1.0 / guessable_words.count.to_f))
      (score - (score * BASE_INCONFIDENCE)).round
    end

    # TODO: if word guess has green chars, previous
    # word guesses are more likely to have those green chars
    # as yellow chars

    def known_letters_with_indexes
      letters_grouped_by_hint_char["g"]&.map do |letter|
        [letter.answer_char, letter.index]
      end
    end

    def yellow_letter_indexes
      letters_grouped_by_hint_char["y"]&.map(&:index)
    end

    private

    def compute_guessable_words
      words = compute_guessable_words_from_hints || Decoder.all
      return words if words.count == 1

      remove_not_guessable_words(words)
    end

    def compute_guessable_words_from_hints
      words = nil
      %w[g y].each do |hint_char|
        letters = letters_grouped_by_hint_char[hint_char]
        words = filter_by_guessable_words(words, letters) if letters
      end
      words
    end

    def remove_not_guessable_words(words)
      letters_grouped_by_hint_char["b"]&.each do |letter|
        words -= letter.not_guessable_words
      end
      words
    end

    def letters_grouped_by_hint_char
      @letters_grouped_by_hint_char ||= @letter_guesses.group_by(&:hint_char)
    end

    def filter_by_guessable_words(words, letters)
      letters.each do |letter|
        if words
          words &= letter.guessable_words
        else
          words = letter.guessable_words
        end
      end
      words
    end

    def initialize_letter_guesses(hint_line, answer_chars)
      hint_line.each_char.map.with_index do |hint_char, index|
        LetterGuess.new(hint_char, answer_chars, index)
      end
    end

    class LetterGuess
      EMOJI_HINT_CHARS = { "⬛" => "b",
                           "🟨" => "y",
                           "🟩" => "g" }.freeze

      def initialize(hint_char, answer_chars, index)
        @hint_char = EMOJI_HINT_CHARS[hint_char] || hint_char
        @answer_chars = answer_chars
        @index = index
        @answer_char = @answer_chars[index]
      end

      attr_reader :hint_char,
                  :answer_char,
                  :index

      def guessable_words
        case hint_char
        when "g"
          Word.with_char_at_index(@answer_char, @index)
        when "y"
          chars = @answer_chars - [@answer_char]
          Word.with_chars_at_index(chars, @index)
        end
      end

      def not_guessable_words
        Word.with_chars_at_index(@answer_chars, @index)
      end
    end
  end
end
