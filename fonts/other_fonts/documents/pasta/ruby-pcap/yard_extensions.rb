class MyClassHandler < YARD::Handlers::C::Base
  include YARD::Parser::C
  include YARD::CodeObjects

  match1 = /([\w\.]+)\s* = \s*(?:rb_define_class|boot_defclass)\s*
            \(
               \s*"([\w:]+)",
               \s*(\w+|0)\s*
            \)/mx

  match2 = /([\w\.]+)\s* = \s*rb_define_class_under\s*
            \(
               \s*(\w+),
               \s*"(\w+)"(?:,
               \s*([\w\*\s\(\)\.\->]+)\s*)?  # for SWIG
            \s*\)/mx
  handles match1
  handles match2
  statement_class BodyStatement

  def my_find_class_body(object)
    unless statement.comments.nil? || statement.comments.source.empty?
      register_docstring(object, statement.comments.source, statement)
      return # found docstring
    end 
  end

  def my_handle_class(var_name, class_name, parent, in_module = nil)
    parent = nil if parent == "0" 
    namespace = in_module ? namespace_for_variable(in_module) : YARD::Registry.root
    register YARD::CodeObjects::ClassObject.new(namespace, class_name) do |obj|
      if parent
        parent_class = namespace_for_variable(parent)
        if parent_class.is_a?(Proxy)
          obj.superclass = "::#{parent_class.path}"
          obj.superclass.type = :class
        else
          obj.superclass = parent_class
        end 
      end 
      namespaces[var_name] = obj 
      my_find_class_body(obj) # add for "Overview"
      register_file_info(obj, statement.file, statement.line)
    end 
  end 

  process do
    statement.source.scan(match1) do |var_name, class_name, parent|
      my_handle_class(var_name, class_name, parent)
    end 
    statement.source.scan(match2) do |var_name, in_module, class_name, parent|
      my_handle_class(var_name, class_name, parent, in_module)
    end 
  end 
end

class MyModuleHandler < YARD::Handlers::C::Base
  include YARD::Parser::C
  include YARD::CodeObjects

  match1 = /([\w\.]+)\s* = \s*rb_define_module\s*\(\s*"([\w:]+)"\s*\)/mx
  match2 = /([\w\.]+)\s* = \s*rb_define_module_under\s*\(\s*(\w+),\s*"(\w+)"\s*\)/mx
  handles match1
  handles match2
  statement_class BodyStatement

  def my_find_module_body(object)
    unless statement.comments.nil? || statement.comments.source.empty?
      register_docstring(object, statement.comments.source, statement)
      return # found docstring
    end 
  end

  def my_handle_module(var_name, module_name, in_module = nil)
    namespace = in_module ? namespace_for_variable(in_module) : YARD::Registry.root
    register YARD::CodeObjects::ModuleObject.new(namespace, module_name) do |obj|
      namespaces[var_name] = obj 
      my_find_module_body(obj) # add for "Overview"
      register_file_info(obj, statement.file, statement.line)
    end 
  end 

  process do
    statement.source.scan(match1) do |var_name, module_name|
      my_handle_module(var_name, module_name)
    end 
    statement.source.scan(match2) do |var_name, in_module, module_name|
      my_handle_module(var_name, module_name, in_module)
    end 
  end 
end
