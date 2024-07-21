; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mattr=+sve < %s | FileCheck %s -check-prefixes=CHECK,NO_STREAMING
; RUN: llc -mattr=+sve -force-streaming-compatible -aarch64-sve-vector-bits-min=128 -aarch64-sve-vector-bits-max=128  < %s | FileCheck %s -check-prefixes=CHECK,SVE_128
; RUN: llc -mattr=+sve -force-streaming-compatible -aarch64-sve-vector-bits-min=256 < %s | FileCheck %s -check-prefixes=CHECK,SVE_MIN_256

target triple = "aarch64-unknown-linux-gnu"

define i32 @reduce_uadd_v16i8(<32 x i8> %a) #0 {
; NO_STREAMING-LABEL: reduce_uadd_v16i8:
; NO_STREAMING:       // %bb.0:
; NO_STREAMING-NEXT:    ushll2 v2.8h, v1.16b, #0
; NO_STREAMING-NEXT:    ushll v1.8h, v1.8b, #0
; NO_STREAMING-NEXT:    ushll2 v3.8h, v0.16b, #0
; NO_STREAMING-NEXT:    ushll v0.8h, v0.8b, #0
; NO_STREAMING-NEXT:    uaddl2 v4.4s, v1.8h, v2.8h
; NO_STREAMING-NEXT:    uaddl v1.4s, v1.4h, v2.4h
; NO_STREAMING-NEXT:    uaddl2 v2.4s, v0.8h, v3.8h
; NO_STREAMING-NEXT:    uaddl v0.4s, v0.4h, v3.4h
; NO_STREAMING-NEXT:    add v1.4s, v1.4s, v4.4s
; NO_STREAMING-NEXT:    add v0.4s, v0.4s, v2.4s
; NO_STREAMING-NEXT:    add v0.4s, v0.4s, v1.4s
; NO_STREAMING-NEXT:    addv s0, v0.4s
; NO_STREAMING-NEXT:    fmov w0, s0
; NO_STREAMING-NEXT:    ret
;
; SVE_128-LABEL: reduce_uadd_v16i8:
; SVE_128:       // %bb.0:
; SVE_128-NEXT:    ptrue p0.b
; SVE_128-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE_128-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE_128-NEXT:    uaddv d1, p0, z1.b
; SVE_128-NEXT:    uaddv d0, p0, z0.b
; SVE_128-NEXT:    fmov x8, d1
; SVE_128-NEXT:    fmov x9, d0
; SVE_128-NEXT:    add w0, w9, w8
; SVE_128-NEXT:    ret
;
; SVE_MIN_256-LABEL: reduce_uadd_v16i8:
; SVE_MIN_256:       // %bb.0:
; SVE_MIN_256-NEXT:    ptrue p0.b, vl16
; SVE_MIN_256-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE_MIN_256-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE_MIN_256-NEXT:    splice z0.b, p0, z0.b, z1.b
; SVE_MIN_256-NEXT:    ptrue p0.b, vl32
; SVE_MIN_256-NEXT:    uaddv d0, p0, z0.b
; SVE_MIN_256-NEXT:    fmov x0, d0
; SVE_MIN_256-NEXT:    // kill: def $w0 killed $w0 killed $x0
; SVE_MIN_256-NEXT:    ret
  %1 = zext <32 x i8> %a to <32 x i32>
  %2 = call i32 @llvm.vector.reduce.add.v16i32(<32 x i32> %1)
  ret i32 %2
}

define i32 @reduce_sadd_v16i8(<32 x i8> %a) #0 {
; NO_STREAMING-LABEL: reduce_sadd_v16i8:
; NO_STREAMING:       // %bb.0:
; NO_STREAMING-NEXT:    sshll2 v2.8h, v1.16b, #0
; NO_STREAMING-NEXT:    sshll v1.8h, v1.8b, #0
; NO_STREAMING-NEXT:    sshll2 v3.8h, v0.16b, #0
; NO_STREAMING-NEXT:    sshll v0.8h, v0.8b, #0
; NO_STREAMING-NEXT:    saddl2 v4.4s, v1.8h, v2.8h
; NO_STREAMING-NEXT:    saddl v1.4s, v1.4h, v2.4h
; NO_STREAMING-NEXT:    saddl2 v2.4s, v0.8h, v3.8h
; NO_STREAMING-NEXT:    saddl v0.4s, v0.4h, v3.4h
; NO_STREAMING-NEXT:    add v1.4s, v1.4s, v4.4s
; NO_STREAMING-NEXT:    add v0.4s, v0.4s, v2.4s
; NO_STREAMING-NEXT:    add v0.4s, v0.4s, v1.4s
; NO_STREAMING-NEXT:    addv s0, v0.4s
; NO_STREAMING-NEXT:    fmov w0, s0
; NO_STREAMING-NEXT:    ret
;
; SVE_128-LABEL: reduce_sadd_v16i8:
; SVE_128:       // %bb.0:
; SVE_128-NEXT:    ptrue p0.b
; SVE_128-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE_128-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE_128-NEXT:    saddv d1, p0, z1.b
; SVE_128-NEXT:    saddv d0, p0, z0.b
; SVE_128-NEXT:    fmov x8, d1
; SVE_128-NEXT:    fmov x9, d0
; SVE_128-NEXT:    add w0, w9, w8
; SVE_128-NEXT:    ret
;
; SVE_MIN_256-LABEL: reduce_sadd_v16i8:
; SVE_MIN_256:       // %bb.0:
; SVE_MIN_256-NEXT:    ptrue p0.b, vl16
; SVE_MIN_256-NEXT:    // kill: def $q0 killed $q0 def $z0
; SVE_MIN_256-NEXT:    // kill: def $q1 killed $q1 def $z1
; SVE_MIN_256-NEXT:    splice z0.b, p0, z0.b, z1.b
; SVE_MIN_256-NEXT:    ptrue p0.b, vl32
; SVE_MIN_256-NEXT:    saddv d0, p0, z0.b
; SVE_MIN_256-NEXT:    fmov x0, d0
; SVE_MIN_256-NEXT:    // kill: def $w0 killed $w0 killed $x0
; SVE_MIN_256-NEXT:    ret
  %1 = sext <32 x i8> %a to <32 x i32>
  %2 = call i32 @llvm.vector.reduce.add.v16i32(<32 x i32> %1)
  ret i32 %2
}

attributes #0 = { "target-features"="+sve" }
;; NOTE: These prefixes are unused and the list is autogenerated. Do not add tests below this line:
; CHECK: {{.*}}