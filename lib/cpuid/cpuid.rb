##
# = CPUID
# Module that accesses CPUID information available on x86 processors.
# Currently mostly supports only Intel meanings behind certain values.
module CPUID
  class UnsupportedFunction < StandardError; end
  extend self
  
  VENDOR_ID_FN = 0
  SIGNATURE_FEATURES_FN = 1
  SERIAL_NUMBER_FN = 3
  MAX_EXT_FN     = 0x80000000
  BRAND_STR_FN_1 = 0x80000002
  BRAND_STR_FN_2 = 0x80000003
  BRAND_STR_FN_3 = 0x80000004
  ADDRESS_SIZE_FN = 0x80000008

  
  ##
  # Returns the model information of the processor, which can be used
  # for telling individual processors apart. Note: you will need to use
  # cache information as well to tell some processors apart.
  #
  # @return [Hash] a set of data about the processor. Keys in these results:
  #   :family => the family number of the processor
  #   :model  => the model number of the processor
  #   :type   => what type of processor it is
  #   :step   => the stepping of the processor
  #   :model_string => a textual meaning behind the "type" value
  def model_information
    processor_type = [
  		"Original OEM Processor",
  		"Intel OverDrive",
  		"Dual Processor"
  	]
  	
  	{:family => family, :model => model, :type => type, :step => stepping, :model_string => processor_type[type]}
	end
  
  ##
  # The "stepping" of the processor, in number form. Intel term for differentiating processors.
  #
  # @return [Fixnum] the stepping of the processor. 
  def stepping; signature & 0xF; end
  
  ##
  # The "type" of the processor, in number form. Intel term for differentiating processors.
  # Possible values:
  #
  # 0: Original OEM Processor
  # 1: Intel OverDrive
  # 2: Dual Processor
  #
  # @return [Fixnum] the stepping of the processor.
  def type; (signature >> 12) & 0x3; end
  
  ##
  # The full model number of the intel processor.
  #
  # @return [Fixnum] the full model number of the processor.
  def model 
    ext_model = ((signature >> 16) & 0xf) 
    (ext_model << 4) | ((signature >> 3) & 0xf)
  end
  
  ##
  # The full family number of the intel processor.
  #
  # @return [Fixnum] the full family number of the processor.
  def family
    ext_family =  (signature >> 20) & 0xff
    (ext_family << 4) | ((signature >> 8) & 0xf)
  end
  
  ##
  # Access the serial number of the processor. Will likely fail, because this feature
  # was only enabled for the Pentium III line of intel processors and some very
  # uncommon other manufacturers.
  #
  # TODO: raise UnsupportedFunction if PSN is unavailable instead of retrieving PSN = 0
  #
  # @return [String] the serial number of the processor, in the format 
  #   "XXXX-XXXX-XXXX-XXXX-XXXX-XXXX"
  def processor_serial_number
    eax, ebx, ecx, edx = run_function(SERIAL_NUMBER_FN)
    [signature, edx, ecx].map {|reg| register_to_hex_s(reg)}.join("-")
  end
  
  ##
  # Returns the vendor string, available on all processors. 
  # Examples: "GenuineIntel", "AuthenticAMD"
  #
  # @return [String] vendor string for the process.
  def vendor_string
    eax, ebx, ecx, edx = run_function(VENDOR_ID_FN)
    register_to_s(ebx) + register_to_s(edx) + register_to_s(ecx)
  end
  
  ##
  # Returns the full brand string of the processor
  #
  # @example
  #   CPUID.brand_string
  #   #=> "Intel(R) Core(TM)2 Duo CPU     P8600  @ 2.40GHz\000"
  # @return [String] the brand string of the processor
  def brand_string
    [BRAND_STR_FN_1, BRAND_STR_FN_2, BRAND_STR_FN_3].map do |fxn|
      reg_array_to_s(run_function(fxn))
    end.join
  end
  
  ##
  # Returns the number of maximum bits in this processor's virtual address space
  def virtual_address_size
    (run_function(ADDRESS_SIZE_FN).first >> 8) & 0xFF
  end
  
  ##
  # Returns the number of maximum bits this processor can address in physical memory
  def physical_address_size
    run_function(ADDRESS_SIZE_FN).first & 0xFF
  end
  
  #private
  
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