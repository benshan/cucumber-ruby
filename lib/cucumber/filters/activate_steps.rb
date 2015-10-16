require 'cucumber/core/filter'
require 'cucumber/step_match'
require 'cucumber/events'
require 'cucumber/errors'

module Cucumber
  module Filters
    class ActivateSteps < Core::Filter.new(:step_definitions, :configuration)

      def test_case(test_case)
        CaseFilter.new(test_case, step_definitions, configuration).test_case.describe_to receiver
      end

      class CaseFilter
        def initialize(test_case, step_definitions, configuration)
          @original_test_case = test_case
          @step_definitions = step_definitions
          @configuration = configuration
        end

        def test_case
          @original_test_case.with_steps(new_test_steps)
        end

        private

        def new_test_steps
          @original_test_case.test_steps.map(&self.method(:attempt_to_activate))
        end

        def attempt_to_activate(test_step)
          find_match(test_step).activate(test_step)
        end

        def find_match(test_step)
          match = find_match2(test_step)
          @configuration.notify Events::StepMatch.new(test_step, match) if match
          return NoStepMatch.new(test_step.source.last, test_step.name) unless match
          return SkippingStepMatch.new if @configuration.dry_run?
          match
        end

        def find_match2(test_step)
          begin
            step_matches(test_step.name).first
          rescue Cucumber::Undefined
            return nil
          end
        end

        def step_matches(step_name)
          matches = @step_definitions.step_matches(step_name)
          raise Undefined.new(step_name) if matches.empty?
          matches = best_matches(step_name, matches) if matches.size > 1 && guess_step_matches?
          raise Ambiguous.new(step_name, matches, guess_step_matches?) if matches.size > 1
          matches
        end

      end
    end
  end
end
