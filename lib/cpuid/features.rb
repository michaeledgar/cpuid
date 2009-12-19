module CPUID
  module Features
    class << self
      def bit(n); 1 << n; end
    end
    
    SIGNATURE_FEATURES_FN = 1
    THERMAL_SENSOR_FN     = 6
    EXT_FEATURE_FN = 0x80000001
    
    POWER_MANAGEMENT_FN = 0x80000007
      
    INTEL_SYSCALL_BIT = bit 11
    INTEL_XD_BIT      = bit 20
    INTEL_64_BIT      = bit 29
    INTEL_LAHF_BIT    = bit 0
    INTEL_TSC_INVARIANCE_BIT = bit 7
    
    TURBO_BOOST_BIT    = bit 1
    THERMAL_SENSOR_BIT = bit 0
    HARDWARE_COORDINATION_FEEDBACK_BIT = bit 0
    
    FPU_BIT  = bit 0
    VME_BIT  = bit 1
    DE_BIT   = bit 2
    PSE_BIT  = bit 3
    TSC_BIT  = bit 4
    MSR_BIT  = bit 5
    PAE_BIT  = bit 6
    MCE_BIT  = bit 7
    CX8_BIT  = bit 8
    APIC_BIT = bit 9
    SEP_BIT  = bit 11
    MTRR_BIT = bit 12
    PGE_BIT  = bit 13
    MCA_BIT  = bit 14
    CMOV_BIT = bit 15
    PAT_BIT  = bit 16
    PSE36_BIT= bit 17
    PSN_BIT  = bit 18
    CLFSH_BIT= bit 19
    DS_BIT   = bit 21
    ACPI_BIT = bit 22
    MMX_BIT  = bit 23
    FXSR_BIT = bit 24
    SSE_BIT  = bit 25
    SSE2_BIT = bit 26
    SS_BIT   = bit 27
    HTT_BIT  = bit 28
    TM_BIT   = bit 29
    PBE_BIT  = bit 31
    
    def features
      @features ||= load_features
    end
    
    private
    
    def load_features
      result = {}
      
      eax, ebx, ecx, edx = run_function(SIGNATURE_FEATURES_FN)
      result[:fpu]   = (edx & FPU_BIT) > 0
      result[:vme]   = (edx & VME_BIT) > 0
      result[:de]    = (edx & DE_BIT)  > 0
      result[:pse]   = (edx & PSE_BIT) > 0
      result[:tsc]   = (edx & TSC_BIT) > 0
      result[:msr]   = (edx & MSR_BIT) > 0
      result[:pae]   = (edx & PAE_BIT) > 0
      result[:mce]   = (edx & MCE_BIT) > 0
      result[:cx8]   = (edx & CX8_BIT) > 0
      result[:apic]  = (edx & APIC_BIT) > 0
      result[:mtrr]  = (edx & MTRR_BIT) > 0
      result[:pge]   = (edx & PGE_BIT) > 0
      result[:mca]   = (edx & MCA_BIT)  > 0
      result[:cmov]  = (edx & CMOV_BIT) > 0
      result[:pat]   = (edx & PAT_BIT) > 0
      result[:pse36] = (edx & PSE36_BIT) > 0
      result[:psn]   = (edx & PSN_BIT) > 0
      result[:clfsh] = (edx & CLFSH_BIT) > 0
      result[:ds]    = (edx & DS_BIT) > 0
      result[:acpi]  = (edx & ACPI_BIT) > 0
      result[:mmx]   = (edx & MMX_BIT) > 0
      result[:fxsr]  = (edx & FXSR_BIT) > 0
      result[:sse]   = (edx & SSE_BIT) > 0
      result[:sse2]  = (edx & SSE2_BIT) > 0
      result[:ss]    = (edx & SS_BIT) > 0
      result[:htt]   = (edx & HTT_BIT) > 0
      result[:tm]    = (edx & TM_BIT) > 0
      result[:pbe]   = (edx & PBE_BIT) > 0
      
      ext_features  = run_function(EXT_FEATURE_FN)
      result[:syscall] = (ext_features[3] & INTEL_SYSCALL_BIT) > 0
      result[:xd_bit]  = (ext_features[3] & INTEL_XD_BIT) > 0
      result[:lahf]    = (ext_features[2] & INTEL_LAHF_BIT) > 0
      result[:x64]     = (ext_features[3] & INTEL_64_BIT) > 0
      
      power_features = run_function(POWER_MANAGEMENT_FN)
      result[:tsc_invariance]  = (power_features.last & INTEL_TSC_INVARIANCE_BIT) > 0
      
      eax, ebx, ecx, edx = run_function(THERMAL_SENSOR_FN)
      result[:turbo_boost] = (eax & TURBO_BOOST_BIT) > 0
      result[:thermal_sensor] = (eax & THERMAL_SENSOR_BIT) > 0
      result[:interrupt_thresholds] = ebx & 0xF
      result[:hardware_coordination_feedback] = (ecx & HARDWARE_COORDINATION_FEEDBACK_BIT) > 0
      
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