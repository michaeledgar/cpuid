module CPUID
  module Processor
    
    VENDOR_ID_FN = 0
    SIGNATURE_FEATURES_FN = 1
    SERIAL_NUMBER_FN = 3
    MAX_EXT_FN     = 0x80000000
    BRAND_STR_FN_1 = 0x80000002
    BRAND_STR_FN_2 = 0x80000003
    BRAND_STR_FN_3 = 0x80000004
    EXT_L2_FN      = 0x80000006
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
    # Is the processor an Intel-made processor?
    def intel?
      vendor_string == "GenuineIntel"
    end

    ##
    # Is the process an AMD-made processor?
    def amd?
      vendor_string == "AuthenticAMD"
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
      raise UnsupportedFunction.new("Your processor does not support a serial number.") unless psn?
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

    ##
    # Access L2 information via the extended function, 0x80000006.
    def easy_L2_info
      ecx = run_function(SIGNATURE_FEATURES_FN)[2]
      assoc_bits = ((ecx >> 12) & 0xF)
      assoc = {}
      case assoc_bits
      when 0x0
        assoc[:disabled] = true
      when 0xF
        assoc[:fully_associative] = true
      else
        assoc[:direct_mapped] = true if assoc_bits & 0x1 > 0
        assoc[:sixteen_way] = true   if assoc_bits & 0x8 > 0
        assoc[:eight_way] = true     if assoc_bits & 0x6 > 0
        assoc[:four_way] = true      if assoc_bits & 0x4 > 0
        assoc[:two_way] = true       if assoc_bits & 0x2 > 0
      end
      {:line_size => ecx & 0xFF, :cache_size => (ecx >> 16) * 1024, :associativity => assoc}
    end
  end
end