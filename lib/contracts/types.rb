module Contracts
    class Type
        def &(other)
            IntersectionType.new([self, other])
        end

        def |(other)
            UnionType.new([self, other])
        end
    end

    class AnyType < Type
        def check(x)
            true
        end
    end

    class VoidType < Type
        def check(x)
            false
        end
    end

    class UnionType < Type
        def initialize(children)
            @children = children
        end

        def check(x)
            @children.any? do |child|
                child.check x
            end
        end
    end

    class IntersectionType < Type
        def initialize(children)
            @children = children
        end

        def check(x)
            @children.all? do |child|
                child.check x
            end
        end
    end

    class ClassType < Type
        def initialize(c)
            @class = c
        end

        def check(x)
            @class === x
        end
    end

    class MinimumType < ClassType
        def initialize(minimum)
            @minimum = minimum
        end

        def check(x)
            puts '----'
            p @minimum
            puts '----'
            @minimum <= x
        end
    end

    class MaximumType < ClassType
        def initialize(maximum)
            @maximum = maximum
        end

        def check(x)
            x <= @maximum
        end
    end

    class IntegerType < ClassType
        def initialize(minimum: -1.0/0.0, maximum: 1.0/0.0)
            super(Integer)

            @minimum = minimum
            @maximum = maximum
        end

        def check(x)
            super(x) && @minimum <= x && x <= @maximum
        end
    end

    class StringType < ClassType
        def initialize(regex: //)
            super(String)

            @regex = regex
        end

        def check(x)
            super(x) && @regex =~ x
        end
    end

    class IsType < ClassType
        def initialize(method)
            @method = method
        end

        def check(x)
            if x.send @method
                true
            else
                false
            end
        end
    end

    class IsNotType < ClassType
        def initialize(method)
            @method = method
        end

        def check(x)
            if x.send @method
                false
            else
                true
            end
        end
    end

    class HasType < ClassType
        def initialize(member, expected_type = AnyType.new)
            @member = member
            @expected_type = expected_type
        end

        def check(x)
            if x.respond_to? @member
                @expected_type.check(x.send @member)
            else
                false
            end
        end
    end

    class ValueType < Type
        def initialize(value)
            @value = value
        end

        def check(x)
            x == @value
        end
    end

    class ArrayType < Type
        def initialize(element_type)
            @element_type = element_type
        end

        def check(x)
            Array === x and x.all? { |elt| @element_type.check elt }
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
                raise "Type class #{type.inspect} should be subclass of type" unless type < Contracts::Type

                add_type(name) { |*args| type.new(*args) }
            end
        end

        add_type :any, AnyType
        add_type :void, VoidType
        add_type :string, StringType
        add_type :is, IsType
        add_type :is_not, IsNotType
        add_type :has, HasType
        add_type :of_class, ClassType
        add_type :value, ValueType
        add_type :array, ArrayType

        add_type :one_of do |*values|
            UnionType.new( values.map { |x| value x } )
        end

        add_type :in_range do |minimum: nil, maximum: nil|
            result = any

            if minimum
                result = result & MinimumType.new(minimum)
            end

            if maximum
                result = result & MaximumType.new(maximum)
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