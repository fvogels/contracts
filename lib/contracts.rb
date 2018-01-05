require "contracts/version"
require 'contracts/types'


module Contracts
    class ContractContext
        include Contracts::TypeMixin

        def initialize(environment)
            @environment = environment
        end

        def typecheck(**kwargs)
            kwargs.each do |variable, type|
                value = eval(variable.to_s, @environment)
            end
        end
    end

    module Core
        def self.contract(&block)
            context = ContractContext.new(block.binding)

            context.instance_eval(&block)
        end
    end
end
