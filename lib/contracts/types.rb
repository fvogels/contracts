module Contracts
    module Types
        class Success
            def and_also
                yield
            end

            def or_else
                self
            end

            def success?
                true
            end
        end

        class Failure
            def initialize(*reasons)
                @reasons = reasons
            end

            attr_reader :reasons

            def or_else
                other = yield

                if other.success?
                    other
                else
                    Failure.new(@reasons + other.reasons)
                end
            end

            def success?
                false
            end

            def and_also
                self
            end
        end

        class Type
            def &(other)
                IntersectionType.new([self, other])
            end

            def |(other)
                UnionType.new([self, other])
            end

            def success
                Success.new
            end

            def failure(reason)
                Failure.new reason
            end

            def assert(message)
                if yield
                    success
                else
                    failure message
                end
            end
        end

        class AnyType < Type
            def check(x)
                success
            end
        end

        class VoidType < Type
            def check(x)
                failure "#{x.inspect} should be void (which is impossible)"
            end
        end

        class UnionType < Type
            def initialize(children)
                @children = children
            end

            def check(x)
                @children.inject(success) do |result, child|
                    result.or_else { child.check(x) }
                end
            end
        end

        class IntersectionType < Type
            def initialize(children)
                @children = children
            end

            def check(x)
                @children.inject(success) do |result, child|
                    result.and_also { child.check(x) }
                end
            end
        end

        class ClassType < Type
            def initialize(c)
                @class = c
            end

            def check(x)
                assert("#{x.inspect} should be of class #{@class}") { @class === x }
            end
        end

        class MinimumType < Type
            def initialize(minimum)
                @minimum = minimum
            end

            def check(x)
                assert("#{x.inspect} should not be less than #{@minimum}") { @minimum <= x }
            end
        end

        class MaximumType < Type
            def initialize(maximum)
                @maximum = maximum
            end

            def check(x)
                assert("#{x.inspect} should not be greater than #{@maximum}") { x <= @maximum }
            end
        end
        
        class RegexType < Type
            def initialize
                @regex = regex
            end

            def check(x)
                assert("#{x.inspect} should satisfy #{regex.inspect}") { @regex =~ x }
            end
        end

        class IsType < Type
            def initialize(method)
                @method = method
            end

            def check(x)
                assert("#{x.inspect} should be #{@method}") { x.send @method }
            end
        end

        class IsNotType < Type
            def initialize(method)
                @method = method
            end

            def check(x)
                assert("#{x.inspect} should not be #{@method}") { not (x.send @method) }
            end
        end

        class HasType < Type
            def initialize(member, expected_type = AnyType.new)
                @member = member
                @expected_type = expected_type
            end

            def check(x)
                assert("#{x.inspect} should have member #{@member} with type #{@expected_type}") do
                    x.respond_to? @member
                end.and_also do
                    @expected_type.check(x.send @member)
                end
            end
        end

        class ValueType < Type
            def initialize(value)
                @value = value
            end

            def check(x)
                assert("#{x.inspect} must be equal to #{@value}") { x == @value }
            end
        end

        class ArrayType < Type
            def initialize(element_type)
                @element_type = element_type
            end

            def check(x)
                assert("#{x.inspect} must be an array") do
                    Array === x
                end.and_also do
                    x.inject(success) { |result, elt| result.and_also { @element_type.check elt } }
                end
            end
        end
    end

    module TypeMixin
        def self.add_type(name, type = nil, &block)
            if block_given?
                raise "Cannot specify both type and block" if type

                Contracts::TypeMixin.instance_eval do
                    define_method(name, &block)
                end
            else
                raise "Missing type" unless type
                raise "Type class #{type.inspect} should be subclass of type" unless type < Contracts::Types::Type

                add_type(name) { |*args| type.new(*args) }
            end
        end

        add_type :any, Types::AnyType
        add_type :void, Types::VoidType        
        add_type :is, Types::IsType
        add_type :is_not, Types::IsNotType
        add_type :has, Types::HasType
        add_type :of_class, Types::ClassType
        add_type :value, Types::ValueType
        add_type :array, Types::ArrayType

        add_type :one_of do |*values|
            Types::UnionType.new( values.map { |x| value x } )
        end

        add_type :in_range do |minimum: nil, maximum: nil|
            result = any

            if minimum
                result = result & Types::MinimumType.new(minimum)
            end

            if maximum
                result = result & Types::MaximumType.new(maximum)
            end

            result
        end

        add_type :string do |regex: nil|
            result = of_class(String)
            
            if regex
                result = result & Types::RegexType.new(regex)
            end

            result
        end

        add_type :integer do |minimum: nil, maximum: nil|
            of_class(Integer) & in_range(minimum: minimum, maximum: maximum)
        end

        add_type :numeric do |minimum: nil, maximum: nil|
            of_class(Numeric) & in_range(minimum: minimum, maximum: maximum)
        end
    end
end