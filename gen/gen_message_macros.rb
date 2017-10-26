# DynaMix
# Copyright (c) 2013-2017 Borislav Stanimirov, Zahary Karadjov
#
# Distributed under the MIT Software License
# See accompanying file LICENSE.txt or copy at
# https://opensource.org/licenses/MIT
#

# script generating message declaration macros

MAX_ARITY = File.open('arity').read.strip.to_i + 1
OUT_FILE = '../include/dynamix/gen/message_macros.hpp'
NO_ARITY_OUT_FILE = '../include/dynamix/gen/no_arity_message_macros.hpp'

HEADER = <<DATA
// DynaMix
// Copyright (c) 2013-2017 Borislav Stanimirov, Zahary Karadjov
//
// Distributed under the MIT Software License
// See accompanying file LICENSE.txt or copy at
// https://opensource.org/licenses/MIT
//
// this file is automatically generated by a script
//

DATA

###################################
# arity generation

DECL = File.open('message_macros_template', 'r').read

def params_for_arity(arity)

  return {
    :arity => 0, :args => '', :arg_types => '', :args_coma => '', :args_signature => '',
    :coma_args_signature => '',
    :coma_args => '', :coma_arg_types => '', :fwd_args => '', :coma_fwd_args => ''
  } if arity == 0

  args = []
  arg_types = []
  caller_args = []
  caller_arg_types = []
  arity.times do |i|
    args << "a#{i}"
    arg_types << "arg#{i}_type"
  end

  args_coma = ', ' + arg_types.zip(args).flatten.join(', ')
  args_signature = arg_types.zip(args).map { |tuple| tuple.join(' ') }. join(', ')
  fwd_args = arg_types.zip(args).map { |type, arg| "std::forward<#{type}>(#{arg})" }. join(', ')
  args = args.join(', ')
  arg_types = arg_types.join(', ')

  {
    :arity => arity, :args => args, :arg_types => arg_types, :args_coma => args_coma, :args_signature => args_signature,
    :coma_args_signature => ', ' + args_signature,
    :coma_args => ', ' + args, :coma_arg_types => ', ' + arg_types,
    :fwd_args => fwd_args, :coma_fwd_args => ', ' + fwd_args
  }

end

File.open(OUT_FILE, 'w') do |f|
  f.write(HEADER)
  MAX_ARITY.times do |i|
    params = params_for_arity(i)
    f.write(DECL % params)
  end
end

##########################
# no-arity generation

args = { :args => (0..(MAX_ARITY-2)).map { |i| "arg#{i}_type, a#{i}" }.join(', ') + ", MACRO, ..." }
empty_arity = {:arity => ''}

output = []

File.open('no_arity_message_macros_template', 'r').each_line do |line|
  next if line.strip!.length == 0
  macro_arity = line.match(/D[^\(]+/)[0]
  macro_args = line.match(/\(.+\)/)[0]

  macro = macro_arity % empty_arity
  get_macro = "_GET_#{macro}_MACRO"

  arity_macros = (MAX_ARITY-1).downto(0).to_a.map { |i| macro_arity % { :arity => "_#{i}" } }.join(', _DYNAMIX_MESSAGE_ARG_ERROR, ')

  output << "#define #{macro}(...) \\\n   _DYNAMIX_VA_ARGS_PROXY(#{get_macro}, (__VA_ARGS__, #{arity_macros}))(__VA_ARGS__)"
  output << "#define #{get_macro}#{macro_args % args} MACRO"
end

File.open(NO_ARITY_OUT_FILE, 'w') do |f|
  f.write(HEADER)
  f.write(output.join("\n"))
  f.write("\n")
end