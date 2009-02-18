#this file contains handy methods and aliases to be used from the console
require 'pp'

module ConsoleExtensions
  def self.included(base)
    base.class_eval %[
      named_scope :find_by_regexp, lambda {|c,v| {:conditions=>[c + " REGEXP ?", v]}}
      def self.find_name_by_regexp(v); find_by_regexp('name', v); end
      class <<self
        alias_method :rn, :find_name_by_regexp
        alias_method :fr, :find_by_regexp
      end
    ]
  end
end

ActiveRecord::Base.class_eval %[
  class<<self
    def inherited(child)
      super
      child.class_eval do
        include ConsoleExtensions
      end
    end
    
    alias_method :f, :find
  end
  
  require 'abbrev'
  def rua(name, value)
    if name = self.class.column_names.abbrev[name.to_s]
      update_attribute(name, value)
    else
      puts "'\#{name}' doesn't match a column"
    end
  end

  def self.fn(*args); self.find_by_name(*args); end
]
#since Tag was already defined by gems
Tag.class_eval %[include ConsoleExtensions]

#using local for now
require 'local_gem' # gem install cldwalker-local_gem
LocalGem.local_require 'alias' # gem install cldwalker-alias
Alias.init

Node.class_eval %[
  def u; puts self.outline_update; end
]

def ns; Node.nonsemantic_tree; end
def s; Node.semantic_tree; end
def t; Node.tag_tree; end
def t2; Node.find_by_name('tags2'); end

def st(name)
  Node.status(name)
end

def trn(name)
  Tag.find_name_by_regexp(name.to_s)
end

def tn(name)
  Tag.find_by_name(name.to_s)
end

def tvo(*args)
  Node.tag_node(args.shift).view_otl(*args)
end

def svo(*args)
  Node.semantic_node(args.shift).view_otl(*args)
end

def sn(name)
  Node.semantic_node(name)
end

def tags(id_or_name)
  node = Node.find_by_id(id_or_name) || Node.find_by_name(id_or_name)
  node.tag_names
end

def change_tag(old_name, new_name)
  Tag.find_by_name(old_name).update_attribute :name, new_name
end

#open url object id
def o(*url_ids)
  urls = url_ids.map {|e| Url.find_by_id(e)}.compact.map {|e| "'#{e.name}'"}
  system("open " + urls.join(" "))
end

#url-paged
def up(offset=nil, limit=20)
  columns = [:id, :name, :tag_list, :facet_type_list]
  #only set if an offset is given
  if offset
    @url_results = uf(offset, limit).amap(*columns)
  end
  pp @url_results
end

#url-find
def uf(offset=0, limit=20)
  Url.find(:all, :offset=>offset, :limit=>limit)
end

#urls-tagged, already formatted
def ut(*args)
  tag = args.shift
  args = [:id, :name, :tag_names] if args.empty?
  pp Url.find_tagged_with(tag).amap(*args)
end

def uc(string)
  Url.quick_create(string)
end

def urn(string)
  Url.find_name_by_regexp(string)
end

class Array
  def amap(*fields)
    map {|e| fields.map {|field| e.send(field) }}
  end
  def method_missing(method,*args,&block)
          shortcut_klasses = [ActiveRecord::Base]
          #if all have one of shortcut klasses as an ancestor
          if self.all? {|e| shortcut_klasses.any? {|k| e.is_a?(k)} }
            self.map {|e| e.send(method,*args,&block) }
          else
            super
          end
  end
end
