# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop identifies places where `sort { |a, b| b <=> a }`
      # can be replaced by a faster `sort.reverse`.
      #
      # @example
      #   # bad
      #   array.sort { |a, b| b <=> a }
      #
      #   # good
      #   array.sort.reverse
      #
      class SortReverse < Cop
        include SortBlock

        MSG = 'Use `sort.reverse` instead of `%<bad_method>s`.'

        def on_block(node)
          sort_with_block?(node) do |send, var_a, var_b, body|
            replaceable_body?(body, var_b, var_a) do
              range = sort_range(send, node)

              add_offense(
                node,
                location: range,
                message: message(var_a, var_b)
              )
            end
          end
        end

        def autocorrect(node)
          sort_with_block?(node) do |send, _var_a, _var_b, _body|
            lambda do |corrector|
              range = sort_range(send, node)
              replacement = 'sort.reverse'
              corrector.replace(range, replacement)
            end
          end
        end

        private

        def message(var_a, var_b)
          bad_method = "sort { |#{var_a}, #{var_b}| #{var_b} <=> #{var_a} }"
          format(MSG, bad_method: bad_method)
        end
      end
    end
  end
end
