
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

  def model_information
    processor_type = [
  		"Original OEM Processor",
  		"Intel OverDrive",
  		"Dual Processor"
  	]

  	eax, ebx, ecx, edx = run_function(SIGNATURE_FEATURES_FN)

  	step = eax & 0xf
  	model = (eax >> 3) & 0xf
  	family = (eax >> 8) & 0xf
  	type = (eax >> 12) & 0x3
  	ext_model = (eax >> 16) & 0xf
  	ext_family = (eax >> 20) & 0xff
  	
  	model = (ext_model << 4) | model
  	family = (ext_family << 4) | family
  	
  	{:family => family, :model => model, :type => type, :step => step, :model_string => processor_type[type]}
	end
  
  def processor_serial_number
    eax, ebx, ecx, edx = run_function(SERIAL_NUMBER_FN)
    [signature, edx, ecx].map {|reg| register_to_hex_s(reg)}.join("-")
  end
  
  def vendor_string
    eax, ebx, ecx, edx = run_function(VENDOR_ID_FN)
    register_to_s(ebx) + register_to_s(edx) + register_to_s(ecx)
  end

  def brand_string
    [BRAND_STR_FN_1, BRAND_STR_FN_2, BRAND_STR_FN_3].map do |fxn|
      reg_array_to_s(run_function(fxn))
    end.join
  end
  
  #private
  
  def signature
    run_function(SIGNATURE_FEATURES_FN).first
  end
  
  def run_function(fn)
    if can_run(fn)
      run_cpuid(fn)
    else
      raise UnsupportedFunction.new("The requested CPUID function 0x#{fn.to_s(16).rjust(8,"0")} is unsupported by your CPU.")
    end
  end
  
  def can_run(fn)
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