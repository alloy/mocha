require 'mocha/metaclass'

module Mocha

  class ClassMethod
  
    attr_reader :stubbee, :method
    
    def initialize(stubbee, method)
      @stubbee = stubbee
      @method = RUBY_VERSION < '1.9' ? method.to_s : method.to_sym
    end
    
    def stub
      hide_original_method
      define_new_method
    end
    
    def unstub
      remove_new_method
      restore_original_method
      stubbee.reset_mocha
    end
    
    def mock
      stubbee.mocha
    end
    
    def hide_original_method
      if method_exists?(method)
        begin
          stubbee.__metaclass__.send(:alias_method, hidden_method, method)
        rescue NameError
          # deal with nasties like ActiveRecord::Associations::AssociationProxy
        end
      end
    end
    
    def define_new_method
      body = if macruby_method?
        macruby_method
      else
        %{
          def #{method}(*args, &block)
            mocha.method_missing(:#{method}, *args, &block)
          end
        }
      end
      stubbee.__metaclass__.class_eval(body, __FILE__, __LINE__)
    end
    
    def remove_new_method
      stubbee.__metaclass__.send(:remove_method, method)
    end
    
    def restore_original_method
      if method_exists?(hidden_method)
        begin
          stubbee.__metaclass__.send(:alias_method, method, hidden_method)
          stubbee.__metaclass__.send(:remove_method, hidden_method)
        rescue NameError
          # deal with nasties like ActiveRecord::Associations::AssociationProxy
        end
      end
    end
    
    def hidden_method
      if RUBY_VERSION < '1.9'
        method_name = method.to_s.gsub(/\W/) { |s| "_substituted_character_#{s[0]}_" }
      else
        method_name = method.to_s.gsub(/\W/) { |s| "_substituted_character_#{s.ord}_" }
      end
      hidden_method = "__stubba__#{method_name}__stubba__"
      RUBY_VERSION < '1.9' ? hidden_method.to_s : hidden_method.to_sym
    end
    
    def eql?(other)
      return false unless (other.class == self.class)
      (stubbee.object_id == other.stubbee.object_id) and (method == other.method)
    end
    
    alias_method :==, :eql?
    
    def to_s
      "#{stubbee}.#{method}"
    end
    
    def method_exists?(method)
      symbol = method.to_sym
      metaclass = stubbee.__metaclass__
      metaclass.public_method_defined?(symbol) || metaclass.protected_method_defined?(symbol) || metaclass.private_method_defined?(symbol)
    end
    
    def macruby_method?
      method.to_s.include?(':')
    end
    
    def macruby_method
      parts = method.to_s.split(':')
      
      signature = "#{parts.shift}(param0"
      parts.each_with_index { |part, index| signature << ", #{part}: param#{index + 1}" }
      signature << ", &block)"
      
      %{
        def #{signature}                                                            # def method(param0, withExtraParam: param1, &block)
          mocha.method_missing(                                                     #   mocha.method_missing(
            '#{method}'.to_sym,                                                     #     'method:withExtraArg:'.to_sym,
            #{Array.new(parts.length + 1) { |index| "param#{index}" }.join(', ')},  #     param0, param1,
            &block)                                                                 #     &block)
        end                                                                         # end
      }
    end
    
  end
  
end
