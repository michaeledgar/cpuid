module CPUID
  module Features
    SIGNATURE_FEATURES_FN = 1
    EXT_FEATURE_FN = 0x80000001
    POWER_MANAGEMENT_FN = 0x80000007
      
    INTEL_SYSCALL_CHECK_BIT = 1 << 11
    INTEL_XD_CHECK_BIT = 1 << 20
    INTEL_64_CHECK_BIT = 1 << 29
    INTEL_LAHF_CHECK_BIT = 1
    INTEL_TSC_INVARIANCE_CHECK_BIT = 1 << 7
    
    def features
      @features ||= load_features
    end
    
    private
    
    def load_features
      result = {}
      
      ext_features  = run_function(EXT_FEATURE_FN)
      result[:syscall] = (ext_features[3] & INTEL_SYSCALL_CHECK_BIT) > 0
      result[:xd_bit]  = (ext_features[3] & INTEL_XD_CHECK_BIT) > 0
      result[:lahf]    = (ext_features[2] & INTEL_LAHF_CHECK_BIT) > 0
      result[:x64]     = (ext_features[3] & INTEL_64_CHECK_BIT) > 0
      
      power_features = run_function(POWER_MANAGEMENT_FN)
      result[:tsc_invariance]  = (power_features.last & INTEL_TSC_INVARIANCE_CHECK_BIT) > 0
      
      result
    end
    
    def method_missing(meth, *args, &block)
      if features.include?(meth)
        features[meth]
      elsif meth.to_s[-1,1] == "?" && features.include?(meth.to_s[0..-2].to_sym)
        features[meth.to_s[0..-2].to_sym]
      else
        super(meth, *args, &block)
      end
    end
    
  end
end