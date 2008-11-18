#!/usr/bin/env ruby -w
# quick and dirty hack to generate function signatures for ruby-ffi from ncurses.h
require 'rubygems'
require 'pp'
require 'ffi'

signatures = []
filename = ARGV[0] || '/usr/include/ncurses.h'

# the abstract _p types can be changed to :pointer (= void *)

NCURSES_ATTR_T = :uint
ATTR_T = :uint
ATTR_T_P = :pointer
SCREEN_P = :pointer
WINDOW_P = :pointer
CHTYPE = :uint
MEVENT_P = :pointer
CHTYPE_P = :pointer
INT_P = :pointer
CCHAR_T_P = :pointer
FILE_P = :pointer
MMASK_T = :uint
MMASK_T_P = :pointer
SHORT_P = :pointer
BOOLEAN = :int

@typemap = {
  "..." => [:unmapped, :variadic],
  "FILE*" => FILE_P,
  "MEVENT*" => MEVENT_P,
  "NCURSES_ATTR_T" => NCURSES_ATTR_T,
  "SCREEN*" => SCREEN_P,
  "WINDOW*" => WINDOW_P,
  "attr_t" => ATTR_T,
  "attr_t*" => ATTR_T_P,       #
  "bool" => BOOLEAN,
  "cchar_t*" => CCHAR_T_P,     # wide character support? - cchar_t is a struct
  "char" => :char,
  "char*" => :string,
  "chtype" => CHTYPE,
  "chtype*" => CHTYPE_P,       #
  "int" => :int,
  "int*" => INT_P,             #
  "long" => :long,
  "mmask_t" => MMASK_T,
  "mmask_t*" => MMASK_T_P,     #
  "short" => :short,
  "short*" => SHORT_P,         #
  "unsigned int" => :uint,
  "va_list" => [:unmapped, :va_list],
  "void" => :void,
  "void*" => :pointer,
}

def map_type(t)
  t = t.gsub(/(NCURSES_)?CONST/i,'').strip.gsub(/\s+\*/, '*')
  @typemap.key?(t) ? @typemap[t] : [:unmapped, t]
end

# these patterns are specific to the ncurses.h include file
RX_RETURN_TYPE = '\\(.*?\\)'
RX_IDENTIFIER = '[A-Za-z_][A-Za-z_0-9]*'
RX_ARGS = "\\((.*?)\\)"
RX_BRACKETS = '[()]'
RX_EXPORT = 'extern\\s+((NCURSES_)?EXPORT)?'

IO.readlines(filename).each do |line|
  if line =~ /#{RX_EXPORT}\s*\(/i
    txt = line.gsub(/#{RX_EXPORT}/i, '')
    return_type = txt.match(/(#{RX_RETURN_TYPE})/).captures[0]
    return_type = return_type.gsub(/#{RX_BRACKETS}/, '')
    return_type = map_type(return_type)

    method_name = txt.match(/(?:#{RX_RETURN_TYPE})\s*(#{RX_IDENTIFIER})/).captures[0]
    match = txt.match(/(?:#{RX_RETURN_TYPE})\s*(?:#{RX_IDENTIFIER})\s*(#{RX_ARGS})/)
    if match
      args = match.captures[0]
      args = args.gsub(/#{RX_BRACKETS}/, '').split(/\s*,\s*/).map{|x| map_type(x)}
    else
      STDERR.puts "No args for method - #{method_name} - #{txt}"
      args = nil
    end
    signatures << [method_name.to_sym, args == [:void] ? [] : args, return_type]
  end
end

# discard sigs of functions we can't handle
unmapped, sigs = signatures.partition{ |s| s.flatten.include?(:unmapped)}
pp sigs.sort_by { |x| x.to_s }

puts "# #{sigs.size}"
puts "# #{unmapped.size}"
