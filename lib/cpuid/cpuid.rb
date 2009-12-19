require 'cpuid/features'
require 'cpuid/processor'

##
# = CPUID
# Module that accesses CPUID information available on x86 processors.
# Currently mostly supports only Intel meanings behind certain values.
module CPUID
  class UnsupportedFunction < StandardError; end
  include Features
  include Processor
  
  extend self

  ###########################################
  # Support functions for the CPUID module. #
  ###########################################
  
  #private
  
  def supports_easy_L2?
    EXT_L2_FN <= max_extended_param
  end
  
  def signature
    @signature ||= run_function(SIGNATURE_FEATURES_FN).first
  end
  
  ##
  # Only runs the given CPUID function if the processor supports it, by checking the
  # processor's maximum parameter values
  #
  # @raise UnsupportedFunction raised if the requested function is not supported by
  #   the processor
  # @param [Fixnum] fn the function to check and run
  # @return [Array<Fixnum>] an array of 4 values: eax, ebx, ecx, edx, returned by the processor.
  def run_function(fn)
    if can_run?(fn)
      run_cpuid(fn)
    else
      raise UnsupportedFunction.new("The requested CPUID function 0x#{fn.to_s(16).rjust(8,"0")} is unsupported by your CPU.")
    end
  end
  
  ##
  # Checks if the processor supports the given function, by using the
  # processor's maximum parameter functions (also a part of the CPUID information)
  #
  # @param [Fixnum] fn the function to check for availability
  # @return [Boolean] does the processor support the function?
  def can_run?(fn)
    (fn < MAX_EXT_FN && fn <= max_basic_param) || (fn >= MAX_EXT_FN && fn <= max_extended_param)
  end
  
  def max_basic_param
    @max_basic_param ||= run_cpuid(VENDOR_ID_FN).first
  end
  
  def max_extended_param
    @max_extended_param ||= run_cpuid(MAX_EXT_FN).first
  end
  
  def get_byte(reg, i)
  	(reg >> (i * 8)) & 0xFF
  end
  
  ##
  # Converts 4 bytes to 4 characters, reversing the order due to little-endian.
  #
  # @param [Fixnum] reg the register value to convert to a string
  # @return [String] a 4-character string converted from the register
  def register_to_s(reg)
  	str = ""
  	0.upto(3) do |idx|
  		str << (get_byte(reg, idx)).chr
  	end
  	str
  end
  
  def register_to_hex_s(reg)
    str = ""
    nibs = [0,1,2,3].map {|idx| get_byte(reg, idx).to_s(16).rjust(2,"0")}
    str = "#{nibs[0]}#{nibs[1]}-#{nibs[2]}#{nibs[3]}"
  	str
  end
  
  def reg_array_to_s(ary)
    ary.map {|reg| register_to_s(reg)}.join
  end
  
end