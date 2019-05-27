(module
  (type (;0;) (func (param i32 i32 i32) (result i32)))
  (type (;1;) (func (param i32 i32) (result i32)))
  (type (;2;) (func (param i32)))
  (type (;3;) (func (param i32 i32)))
  (type (;4;) (func (param i64 i32) (result i32)))
  (type (;5;) (func (param i32) (result i64)))
  (type (;6;) (func))
  (type (;7;) (func (param i32 i32)))
  (type (;8;) (func (param i32 i32 i32) (result i32)))
  (func (;0;) (type 6)
    (local i32 i32)
    i32.const 1
    local.set 0
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          i32.const 1049232
          i32.load
          i32.const 1
          i32.eq
          if  ;; label = @4
            i32.const 1049236
            i32.const 1049236
            i32.load
            i32.const 1
            i32.add
            local.tee 0
            i32.store
            local.get 0
            i32.const 3
            i32.lt_u
            br_if 1 (;@3;)
            br 2 (;@2;)
          end
          i32.const 1049232
          i64.const 4294967297
          i64.store
        end
        i32.const 1049240
        i32.load
        local.tee 1
        i32.const -1
        i32.le_s
        br_if 0 (;@2;)
        i32.const 1049240
        local.get 1
        i32.store
        local.get 0
        i32.const 2
        i32.lt_u
        br_if 1 (;@1;)
      end
      unreachable
    end
    unreachable)
  (func (;1;) (type 2) (param i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    local.get 0
    i32.load offset=8
    i32.eqz
    if  ;; label = @1
      i32.const 1049172
      call 2
      unreachable
    end
    local.get 1
    local.get 0
    i32.const 20
    i32.add
    i64.load align=4
    i64.store offset=8
    local.get 1
    local.get 0
    i64.load offset=12 align=4
    i64.store
    call 0
    unreachable)
  (func (;2;) (type 2) (param i32)
    (local i32 i64 i64 i64)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 1
    global.set 0
    local.get 0
    i64.load offset=8 align=4
    local.set 2
    local.get 0
    i64.load offset=16 align=4
    local.set 3
    local.get 0
    i64.load align=4
    local.set 4
    local.get 1
    i32.const 20
    i32.add
    i32.const 0
    i32.store
    local.get 1
    local.get 4
    i64.store offset=24
    local.get 1
    i32.const 1048656
    i32.store offset=16
    local.get 1
    i64.const 1
    i64.store offset=4 align=4
    local.get 1
    local.get 1
    i32.const 24
    i32.add
    i32.store
    local.get 1
    local.get 3
    i64.store offset=40
    local.get 1
    local.get 2
    i64.store offset=32
    local.get 1
    local.get 1
    i32.const 32
    i32.add
    call 5
    unreachable)
  (func (;3;) (type 7) (param i32 i32)
    (local i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 2
    global.set 0
    local.get 2
    i32.const 16
    i32.store offset=4
    local.get 2
    local.get 1
    i32.store
    local.get 2
    i32.const 44
    i32.add
    i32.const 1
    i32.store
    local.get 2
    i32.const 28
    i32.add
    i32.const 2
    i32.store
    local.get 2
    i32.const 1
    i32.store offset=36
    local.get 2
    i64.const 2
    i64.store offset=12 align=4
    local.get 2
    i32.const 1049140
    i32.store offset=8
    local.get 2
    local.get 2
    i32.store offset=40
    local.get 2
    local.get 2
    i32.const 4
    i32.add
    i32.store offset=32
    local.get 2
    local.get 2
    i32.const 32
    i32.add
    i32.store offset=24
    local.get 2
    i32.const 8
    i32.add
    local.get 0
    call 5
    unreachable)
  (func (;4;) (type 1) (param i32 i32) (result i32)
    local.get 0
    i64.load32_u
    local.get 1
    call 6)
  (func (;5;) (type 3) (param i32 i32)
    (local i32 i64)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 2
    global.set 0
    local.get 1
    i64.load align=4
    local.set 3
    local.get 2
    i32.const 20
    i32.add
    local.get 1
    i64.load offset=8 align=4
    i64.store align=4
    local.get 2
    local.get 3
    i64.store offset=12 align=4
    local.get 2
    local.get 0
    i32.store offset=8
    local.get 2
    i32.const 1049156
    i32.store offset=4
    local.get 2
    i32.const 1048656
    i32.store
    local.get 2
    call 1
    unreachable)
  (func (;6;) (type 4) (param i64 i32) (result i32)
    (local i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i64)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 6
    global.set 0
    i32.const 39
    local.set 2
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i64.const 10000
        i64.ge_u
        if  ;; label = @3
          loop  ;; label = @4
            local.get 6
            i32.const 9
            i32.add
            local.get 2
            i32.add
            local.tee 3
            i32.const -4
            i32.add
            local.get 0
            local.get 0
            i64.const 10000
            i64.div_u
            local.tee 13
            i64.const -10000
            i64.mul
            i64.add
            i32.wrap_i64
            local.tee 4
            i32.const 100
            i32.div_u
            local.tee 5
            i32.const 1
            i32.shl
            i32.const 1048706
            i32.add
            i32.load16_u align=1
            i32.store16 align=1
            local.get 3
            i32.const -2
            i32.add
            local.get 5
            i32.const -100
            i32.mul
            local.get 4
            i32.add
            i32.const 1
            i32.shl
            i32.const 1048706
            i32.add
            i32.load16_u align=1
            i32.store16 align=1
            local.get 2
            i32.const -4
            i32.add
            local.set 2
            local.get 0
            i64.const 99999999
            i64.gt_u
            local.get 13
            local.set 0
            br_if 0 (;@4;)
          end
          local.get 13
          i32.wrap_i64
          local.tee 3
          i32.const 99
          i32.le_s
          br_if 2 (;@1;)
          br 1 (;@2;)
        end
        local.get 0
        local.tee 13
        i32.wrap_i64
        local.tee 3
        i32.const 99
        i32.le_s
        br_if 1 (;@1;)
      end
      local.get 2
      i32.const -2
      i32.add
      local.tee 2
      local.get 6
      i32.const 9
      i32.add
      i32.add
      local.get 13
      i32.wrap_i64
      local.tee 4
      i32.const 65535
      i32.and
      i32.const 100
      i32.div_u
      local.tee 3
      i32.const -100
      i32.mul
      local.get 4
      i32.add
      i32.const 65535
      i32.and
      i32.const 1
      i32.shl
      i32.const 1048706
      i32.add
      i32.load16_u align=1
      i32.store16 align=1
    end
    block  ;; label = @1
      local.get 3
      i32.const 9
      i32.le_s
      if  ;; label = @2
        local.get 2
        i32.const -1
        i32.add
        local.tee 2
        local.get 6
        i32.const 9
        i32.add
        i32.add
        local.get 3
        i32.const 48
        i32.add
        i32.store8
        br 1 (;@1;)
      end
      local.get 2
      i32.const -2
      i32.add
      local.tee 2
      local.get 6
      i32.const 9
      i32.add
      i32.add
      local.get 3
      i32.const 1
      i32.shl
      i32.const 1048706
      i32.add
      i32.load16_u align=1
      i32.store16 align=1
    end
    i32.const 39
    local.get 2
    i32.sub
    local.set 7
    i32.const 1
    local.set 3
    i32.const 43
    i32.const 1114112
    local.get 1
    i32.load
    local.tee 4
    i32.const 1
    i32.and
    local.tee 11
    select
    local.set 8
    local.get 4
    i32.const 29
    i32.shl
    i32.const 31
    i32.shr_s
    i32.const 1048656
    i32.and
    local.set 9
    local.get 6
    i32.const 9
    i32.add
    local.get 2
    i32.add
    local.set 10
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                block  ;; label = @7
                  block  ;; label = @8
                    block (result i32)  ;; label = @9
                      block  ;; label = @10
                        block  ;; label = @11
                          block  ;; label = @12
                            block  ;; label = @13
                              local.get 1
                              i32.load offset=8
                              i32.const 1
                              i32.eq
                              if  ;; label = @14
                                local.get 1
                                i32.const 12
                                i32.add
                                i32.load
                                local.tee 5
                                local.get 7
                                local.get 11
                                i32.add
                                local.tee 2
                                i32.le_u
                                br_if 1 (;@13;)
                                local.get 4
                                i32.const 8
                                i32.and
                                br_if 2 (;@12;)
                                local.get 5
                                local.get 2
                                i32.sub
                                local.set 4
                                i32.const 1
                                local.get 1
                                i32.load8_u offset=48
                                local.tee 3
                                local.get 3
                                i32.const 3
                                i32.eq
                                select
                                local.tee 3
                                i32.const 3
                                i32.and
                                i32.eqz
                                br_if 3 (;@11;)
                                local.get 3
                                i32.const 2
                                i32.eq
                                br_if 4 (;@10;)
                                i32.const 0
                                local.set 5
                                local.get 4
                                br 5 (;@9;)
                              end
                              local.get 1
                              local.get 8
                              local.get 9
                              call 9
                              br_if 10 (;@3;)
                              br 11 (;@2;)
                            end
                            local.get 1
                            local.get 8
                            local.get 9
                            call 9
                            br_if 9 (;@3;)
                            br 10 (;@2;)
                          end
                          local.get 1
                          i32.const 1
                          i32.store8 offset=48
                          local.get 1
                          i32.const 48
                          i32.store offset=4
                          local.get 1
                          local.get 8
                          local.get 9
                          call 9
                          br_if 8 (;@3;)
                          local.get 5
                          local.get 2
                          i32.sub
                          local.set 3
                          i32.const 1
                          local.get 1
                          i32.const 48
                          i32.add
                          i32.load8_u
                          local.tee 4
                          local.get 4
                          i32.const 3
                          i32.eq
                          select
                          local.tee 4
                          i32.const 3
                          i32.and
                          i32.eqz
                          br_if 3 (;@8;)
                          local.get 4
                          i32.const 2
                          i32.eq
                          br_if 4 (;@7;)
                          i32.const 0
                          local.set 4
                          br 5 (;@6;)
                        end
                        local.get 4
                        local.set 5
                        i32.const 0
                        br 1 (;@9;)
                      end
                      local.get 4
                      i32.const 1
                      i32.add
                      i32.const 1
                      i32.shr_u
                      local.set 5
                      local.get 4
                      i32.const 1
                      i32.shr_u
                    end
                    local.set 3
                    i32.const -1
                    local.set 2
                    local.get 1
                    i32.const 4
                    i32.add
                    local.set 4
                    local.get 1
                    i32.const 24
                    i32.add
                    local.set 11
                    local.get 1
                    i32.const 28
                    i32.add
                    local.set 12
                    block  ;; label = @9
                      loop  ;; label = @10
                        local.get 2
                        i32.const 1
                        i32.add
                        local.tee 2
                        local.get 3
                        i32.ge_u
                        br_if 1 (;@9;)
                        local.get 11
                        i32.load
                        local.get 4
                        i32.load
                        local.get 12
                        i32.load
                        i32.load offset=16
                        call_indirect (type 1)
                        i32.eqz
                        br_if 0 (;@10;)
                      end
                      br 8 (;@1;)
                    end
                    local.get 1
                    i32.const 4
                    i32.add
                    i32.load
                    local.set 4
                    i32.const 1
                    local.set 3
                    local.get 1
                    local.get 8
                    local.get 9
                    call 9
                    br_if 5 (;@3;)
                    local.get 1
                    i32.const 24
                    i32.add
                    local.tee 2
                    i32.load
                    local.get 10
                    local.get 7
                    local.get 1
                    i32.const 28
                    i32.add
                    local.tee 1
                    i32.load
                    i32.load offset=12
                    call_indirect (type 0)
                    br_if 5 (;@3;)
                    local.get 2
                    i32.load
                    local.set 7
                    i32.const -1
                    local.set 2
                    local.get 1
                    i32.load
                    i32.const 16
                    i32.add
                    local.set 1
                    loop  ;; label = @9
                      local.get 2
                      i32.const 1
                      i32.add
                      local.tee 2
                      local.get 5
                      i32.ge_u
                      br_if 4 (;@5;)
                      local.get 7
                      local.get 4
                      local.get 1
                      i32.load
                      call_indirect (type 1)
                      i32.eqz
                      br_if 0 (;@9;)
                    end
                    br 5 (;@3;)
                  end
                  local.get 3
                  local.set 4
                  i32.const 0
                  local.set 3
                  br 1 (;@6;)
                end
                local.get 3
                i32.const 1
                i32.add
                i32.const 1
                i32.shr_u
                local.set 4
                local.get 3
                i32.const 1
                i32.shr_u
                local.set 3
              end
              i32.const -1
              local.set 2
              local.get 1
              i32.const 4
              i32.add
              local.set 5
              local.get 1
              i32.const 24
              i32.add
              local.set 8
              local.get 1
              i32.const 28
              i32.add
              local.set 9
              block  ;; label = @6
                loop  ;; label = @7
                  local.get 2
                  i32.const 1
                  i32.add
                  local.tee 2
                  local.get 3
                  i32.ge_u
                  br_if 1 (;@6;)
                  local.get 8
                  i32.load
                  local.get 5
                  i32.load
                  local.get 9
                  i32.load
                  i32.load offset=16
                  call_indirect (type 1)
                  i32.eqz
                  br_if 0 (;@7;)
                end
                br 5 (;@1;)
              end
              local.get 1
              i32.const 4
              i32.add
              i32.load
              local.set 5
              i32.const 1
              local.set 3
              local.get 1
              i32.const 24
              i32.add
              local.tee 2
              i32.load
              local.get 10
              local.get 7
              local.get 1
              i32.const 28
              i32.add
              local.tee 1
              i32.load
              i32.load offset=12
              call_indirect (type 0)
              br_if 2 (;@3;)
              local.get 2
              i32.load
              local.set 7
              i32.const -1
              local.set 2
              local.get 1
              i32.load
              i32.const 16
              i32.add
              local.set 1
              loop  ;; label = @6
                local.get 2
                i32.const 1
                i32.add
                local.tee 2
                local.get 4
                i32.ge_u
                br_if 2 (;@4;)
                local.get 7
                local.get 5
                local.get 1
                i32.load
                call_indirect (type 1)
                i32.eqz
                br_if 0 (;@6;)
              end
              br 2 (;@3;)
            end
            local.get 6
            i32.const 48
            i32.add
            global.set 0
            i32.const 0
            return
          end
          i32.const 0
          local.set 3
        end
        local.get 6
        i32.const 48
        i32.add
        global.set 0
        local.get 3
        return
      end
      local.get 1
      i32.load offset=24
      local.get 10
      local.get 7
      local.get 1
      i32.const 28
      i32.add
      i32.load
      i32.load offset=12
      call_indirect (type 0)
      local.get 6
      i32.const 48
      i32.add
      global.set 0
      return
    end
    local.get 6
    i32.const 48
    i32.add
    global.set 0
    i32.const 1)
  (func (;7;) (type 2) (param i32)
    nop)
  (func (;8;) (type 5) (param i32) (result i64)
    i64.const -2357177763932378009)
  (func (;9;) (type 8) (param i32 i32 i32) (result i32)
    block  ;; label = @1
      block (result i32)  ;; label = @2
        local.get 1
        i32.const 1114112
        i32.ne
        if  ;; label = @3
          i32.const 1
          local.get 0
          i32.load offset=24
          local.get 1
          local.get 0
          i32.const 28
          i32.add
          i32.load
          i32.load offset=16
          call_indirect (type 1)
          br_if 1 (;@2;)
          drop
        end
        local.get 2
        i32.eqz
        br_if 1 (;@1;)
        local.get 0
        i32.load offset=24
        local.get 2
        i32.const 0
        local.get 0
        i32.const 28
        i32.add
        i32.load
        i32.load offset=12
        call_indirect (type 0)
      end
      return
    end
    i32.const 0)
  (func (;10;) (type 2) (param i32)
    (local i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32)
    global.get 0
    i32.const 256
    i32.sub
    local.tee 1
    global.set 0
    local.get 1
    i64.const 4294967297
    i64.store offset=56 align=4
    local.get 1
    i64.const 4294967297
    i64.store offset=48 align=4
    local.get 1
    i64.const 4294967297
    i64.store offset=40 align=4
    local.get 1
    i64.const 4294967297
    i64.store offset=32 align=4
    local.get 1
    i64.const 4294967297
    i64.store offset=24 align=4
    local.get 1
    i64.const 4294967297
    i64.store offset=16 align=4
    local.get 1
    i64.const 4294967297
    i64.store offset=8 align=4
    local.get 1
    i64.const 4294967297
    i64.store align=4
    block  ;; label = @1
      local.get 0
      i32.const 1
      i32.add
      local.tee 11
      i32.const 2
      i32.ge_u
      if  ;; label = @2
        local.get 1
        local.set 3
        i32.const 1
        local.set 2
        loop  ;; label = @3
          local.get 2
          i32.const 16
          i32.ge_u
          br_if 2 (;@1;)
          local.get 3
          i32.const 4
          i32.add
          local.tee 4
          local.get 3
          i32.load
          local.get 2
          i32.mul
          i32.store
          local.get 4
          local.set 3
          local.get 2
          i32.const 1
          i32.add
          local.tee 4
          local.set 2
          local.get 4
          local.get 11
          i32.lt_u
          br_if 0 (;@3;)
        end
      end
      local.get 0
      i32.const 16
      i32.lt_u
      if  ;; label = @2
        i32.const 1
        local.set 19
        local.get 1
        local.get 0
        i32.const 2
        i32.shl
        i32.add
        i32.load
        local.tee 8
        local.set 20
        local.get 8
        i32.const 24
        i32.ge_u
        if  ;; label = @3
          i32.const 24
          i32.const 25
          local.get 8
          local.get 8
          i32.const 24
          i32.div_u
          local.tee 20
          i32.const 24
          i32.mul
          i32.eq
          select
          local.set 19
        end
        i32.const 0
        local.get 0
        i32.sub
        local.set 37
        local.get 1
        i32.const 196
        i32.add
        local.set 13
        local.get 1
        i32.const 132
        i32.add
        local.set 38
        local.get 1
        i32.const 124
        i32.add
        local.set 39
        local.get 1
        i32.const 68
        i32.add
        local.set 11
        local.get 0
        i32.const 2
        i32.lt_u
        local.set 40
        loop  ;; label = @3
          local.get 1
          i32.const 120
          i32.add
          i64.const 0
          i64.store
          local.get 1
          i32.const 112
          i32.add
          i64.const 0
          i64.store
          local.get 1
          i32.const 104
          i32.add
          i64.const 0
          i64.store
          local.get 1
          i32.const 96
          i32.add
          i64.const 0
          i64.store
          local.get 1
          i32.const 88
          i32.add
          i64.const 0
          i64.store
          local.get 1
          i32.const 80
          i32.add
          i64.const 0
          i64.store
          local.get 1
          i32.const 72
          i32.add
          i64.const 0
          i64.store
          local.get 1
          i64.const 0
          i64.store offset=64
          local.get 1
          i32.const 184
          i32.add
          local.tee 23
          i64.const 0
          i64.store
          local.get 1
          i32.const 176
          i32.add
          local.tee 24
          i64.const 0
          i64.store
          local.get 1
          i32.const 168
          i32.add
          local.tee 25
          i64.const 0
          i64.store
          local.get 1
          i32.const 160
          i32.add
          local.tee 26
          i64.const 0
          i64.store
          local.get 1
          i32.const 152
          i32.add
          local.tee 27
          i64.const 0
          i64.store
          local.get 1
          i32.const 144
          i32.add
          local.tee 28
          i64.const 0
          i64.store
          local.get 1
          i32.const 136
          i32.add
          local.tee 29
          i64.const 0
          i64.store
          local.get 1
          i64.const 0
          i64.store offset=128
          local.get 1
          i32.const 248
          i32.add
          local.tee 30
          i64.const 64424509454
          i64.store align=4
          local.get 1
          i32.const 240
          i32.add
          local.tee 31
          i64.const 55834574860
          i64.store align=4
          local.get 1
          i32.const 232
          i32.add
          local.tee 32
          i64.const 47244640266
          i64.store align=4
          local.get 1
          i32.const 224
          i32.add
          local.tee 33
          i64.const 38654705672
          i64.store align=4
          local.get 1
          i32.const 216
          i32.add
          local.tee 34
          i64.const 30064771078
          i64.store align=4
          local.get 1
          i32.const 208
          i32.add
          local.tee 35
          i64.const 21474836484
          i64.store align=4
          local.get 1
          i32.const 200
          i32.add
          local.tee 36
          i64.const 12884901890
          i64.store align=4
          local.get 1
          i64.const 4294967296
          i64.store offset=192 align=4
          local.get 12
          local.get 20
          i32.mul
          local.set 9
          block (result i32)  ;; label = @4
            block  ;; label = @5
              local.get 40
              i32.eqz
              if  ;; label = @6
                local.get 37
                local.set 21
                local.get 9
                local.set 14
                local.get 0
                local.set 15
                i32.const 0
                local.set 5
                br 1 (;@5;)
              end
              i32.const 0
              br 1 (;@4;)
            end
            i32.const 1
          end
          local.set 2
          loop  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                block (result i32)  ;; label = @7
                  block  ;; label = @8
                    block  ;; label = @9
                      block  ;; label = @10
                        block  ;; label = @11
                          block  ;; label = @12
                            block  ;; label = @13
                              local.get 2
                              i32.eqz
                              if  ;; label = @14
                                local.get 12
                                i32.const 1
                                i32.add
                                local.set 12
                                local.get 8
                                local.get 9
                                local.get 20
                                i32.add
                                local.tee 3
                                local.get 3
                                local.get 8
                                i32.gt_u
                                select
                                i32.const -1
                                i32.add
                                local.set 41
                                local.get 1
                                i32.load offset=192
                                local.tee 6
                                i32.const 1
                                i32.ge_s
                                br_if 1 (;@13;)
                                br 2 (;@12;)
                              end
                              block  ;; label = @14
                                block  ;; label = @15
                                  block  ;; label = @16
                                    block  ;; label = @17
                                      block  ;; label = @18
                                        block  ;; label = @19
                                          block  ;; label = @20
                                            block  ;; label = @21
                                              block  ;; label = @22
                                                block  ;; label = @23
                                                  block  ;; label = @24
                                                    local.get 5
                                                    br_table 0 (;@24;) 1 (;@23;) 2 (;@22;)
                                                  end
                                                  local.get 15
                                                  i32.const -1
                                                  i32.add
                                                  local.tee 4
                                                  i32.const 16
                                                  i32.ge_u
                                                  br_if 6 (;@17;)
                                                  local.get 1
                                                  local.get 4
                                                  i32.const 2
                                                  i32.shl
                                                  local.tee 2
                                                  i32.add
                                                  i32.load
                                                  local.tee 3
                                                  i32.eqz
                                                  br_if 7 (;@16;)
                                                  local.get 14
                                                  i32.const -2147483648
                                                  i32.eq
                                                  if  ;; label = @24
                                                    local.get 3
                                                    i32.const -1
                                                    i32.eq
                                                    br_if 9 (;@15;)
                                                  end
                                                  local.get 1
                                                  i32.const -64
                                                  i32.sub
                                                  local.get 2
                                                  i32.add
                                                  local.get 14
                                                  local.get 3
                                                  i32.div_s
                                                  local.tee 16
                                                  i32.store
                                                  local.get 29
                                                  local.get 36
                                                  i64.load align=4
                                                  i64.store
                                                  local.get 28
                                                  local.get 35
                                                  i64.load align=4
                                                  i64.store
                                                  local.get 27
                                                  local.get 34
                                                  i64.load align=4
                                                  i64.store
                                                  local.get 26
                                                  local.get 33
                                                  i64.load align=4
                                                  i64.store
                                                  local.get 25
                                                  local.get 32
                                                  i64.load align=4
                                                  i64.store
                                                  local.get 24
                                                  local.get 31
                                                  i64.load align=4
                                                  i64.store
                                                  local.get 23
                                                  local.get 30
                                                  i64.load align=4
                                                  i64.store
                                                  local.get 1
                                                  local.get 1
                                                  i64.load offset=192 align=4
                                                  i64.store offset=128
                                                  local.get 16
                                                  local.get 21
                                                  i32.add
                                                  local.set 42
                                                  local.get 14
                                                  local.get 3
                                                  local.get 16
                                                  i32.mul
                                                  i32.sub
                                                  local.set 14
                                                  i32.const 0
                                                  local.set 2
                                                  local.get 1
                                                  i32.const 192
                                                  i32.add
                                                  local.set 7
                                                  loop  ;; label = @24
                                                    block  ;; label = @25
                                                      local.get 2
                                                      local.get 16
                                                      i32.add
                                                      local.tee 3
                                                      local.get 4
                                                      i32.gt_u
                                                      if  ;; label = @26
                                                        local.get 2
                                                        local.get 42
                                                        i32.add
                                                        local.tee 43
                                                        i32.const 15
                                                        i32.gt_u
                                                        br_if 6 (;@20;)
                                                        local.get 3
                                                        local.get 15
                                                        i32.sub
                                                        local.set 3
                                                        local.get 2
                                                        i32.const 15
                                                        i32.le_u
                                                        br_if 1 (;@25;)
                                                        br 5 (;@21;)
                                                      end
                                                      local.get 3
                                                      i32.const 16
                                                      i32.ge_u
                                                      br_if 6 (;@19;)
                                                      local.get 2
                                                      i32.const 15
                                                      i32.gt_u
                                                      br_if 4 (;@21;)
                                                    end
                                                    local.get 7
                                                    local.get 1
                                                    i32.const 128
                                                    i32.add
                                                    local.get 3
                                                    i32.const 2
                                                    i32.shl
                                                    i32.add
                                                    i32.load
                                                    i32.store
                                                    local.get 7
                                                    i32.const 4
                                                    i32.add
                                                    local.set 7
                                                    local.get 2
                                                    i32.const 1
                                                    i32.add
                                                    local.tee 2
                                                    local.get 15
                                                    i32.lt_u
                                                    br_if 0 (;@24;)
                                                  end
                                                  local.get 21
                                                  i32.const 1
                                                  i32.add
                                                  local.set 21
                                                  local.get 4
                                                  local.tee 15
                                                  i32.const 1
                                                  i32.gt_u
                                                  br_if 9 (;@14;)
                                                  i32.const 0
                                                  local.set 2
                                                  br 19 (;@4;)
                                                end
                                                local.get 23
                                                local.get 30
                                                i64.load align=4
                                                i64.store
                                                local.get 24
                                                local.get 31
                                                i64.load align=4
                                                i64.store
                                                local.get 25
                                                local.get 32
                                                i64.load align=4
                                                i64.store
                                                local.get 26
                                                local.get 33
                                                i64.load align=4
                                                i64.store
                                                local.get 27
                                                local.get 34
                                                i64.load align=4
                                                i64.store
                                                local.get 28
                                                local.get 35
                                                i64.load align=4
                                                i64.store
                                                local.get 29
                                                local.get 36
                                                i64.load align=4
                                                i64.store
                                                local.get 1
                                                local.get 1
                                                i64.load offset=192 align=4
                                                i64.store offset=128
                                                local.get 6
                                                i32.const 15
                                                i32.gt_u
                                                br_if 4 (;@18;)
                                                local.get 6
                                                local.set 10
                                                i32.const 0
                                                br 15 (;@7;)
                                              end
                                              local.get 9
                                              local.get 41
                                              i32.lt_u
                                              if  ;; label = @22
                                                local.get 13
                                                i32.load
                                                local.set 22
                                                local.get 13
                                                local.get 6
                                                i32.store
                                                local.get 1
                                                local.get 22
                                                i32.store offset=192
                                                local.get 11
                                                local.set 17
                                                local.get 1
                                                i32.load offset=68
                                                local.tee 2
                                                i32.const 1
                                                i32.lt_s
                                                br_if 17 (;@5;)
                                                i32.const 1
                                                local.set 18
                                                br 14 (;@8;)
                                              end
                                              local.get 12
                                              local.get 19
                                              i32.lt_u
                                              br_if 18 (;@3;)
                                              local.get 1
                                              i32.const 256
                                              i32.add
                                              global.set 0
                                              return
                                            end
                                            i32.const 1049076
                                            local.get 2
                                            call 3
                                            unreachable
                                          end
                                          i32.const 1049060
                                          local.get 43
                                          call 3
                                          unreachable
                                        end
                                        i32.const 1049044
                                        local.get 2
                                        local.get 16
                                        i32.add
                                        call 3
                                        unreachable
                                      end
                                      local.get 6
                                      local.set 10
                                      br 11 (;@6;)
                                    end
                                    i32.const 1048980
                                    local.get 4
                                    call 3
                                    unreachable
                                  end
                                  i32.const 1048996
                                  call 2
                                  unreachable
                                end
                                i32.const 1049020
                                call 2
                                unreachable
                              end
                              i32.const 0
                              local.set 5
                              br 2 (;@11;)
                            end
                            i32.const 1
                            local.set 5
                            br 2 (;@10;)
                          end
                          i32.const 2
                          local.set 5
                          br 2 (;@9;)
                        end
                        i32.const 1
                        local.set 2
                        br 6 (;@4;)
                      end
                      i32.const 1
                      local.set 2
                      br 5 (;@4;)
                    end
                    i32.const 1
                    local.set 2
                    br 4 (;@4;)
                  end
                  i32.const 1
                end
                local.set 2
                loop  ;; label = @7
                  block  ;; label = @8
                    block  ;; label = @9
                      local.get 2
                      i32.eqz
                      if  ;; label = @10
                        local.get 10
                        local.tee 3
                        i32.const 2
                        i32.shl
                        local.tee 4
                        local.get 1
                        i32.const 128
                        i32.add
                        i32.add
                        local.tee 5
                        i32.load
                        local.tee 10
                        i32.eqz
                        br_if 1 (;@9;)
                        local.get 5
                        local.get 3
                        i32.store
                        block  ;; label = @11
                          local.get 3
                          i32.const 3
                          i32.lt_u
                          br_if 0 (;@11;)
                          local.get 3
                          i32.const -1
                          i32.add
                          i32.const 1
                          i32.shr_u
                          local.tee 7
                          i32.eqz
                          br_if 0 (;@11;)
                          local.get 4
                          local.get 39
                          i32.add
                          local.set 2
                          local.get 38
                          local.set 3
                          loop  ;; label = @12
                            local.get 3
                            i32.load
                            local.set 4
                            local.get 3
                            local.get 2
                            i32.load
                            i32.store
                            local.get 2
                            local.get 4
                            i32.store
                            local.get 3
                            i32.const 4
                            i32.add
                            local.set 3
                            local.get 2
                            i32.const -4
                            i32.add
                            local.set 2
                            local.get 7
                            i32.const -1
                            i32.add
                            local.tee 7
                            br_if 0 (;@12;)
                          end
                        end
                        local.get 10
                        i32.const 16
                        i32.lt_u
                        br_if 2 (;@8;)
                        br 4 (;@6;)
                      end
                      i32.const 0
                      local.set 2
                      local.get 17
                      i32.const 0
                      i32.store
                      local.get 1
                      local.get 6
                      local.tee 4
                      i32.store offset=192
                      local.get 18
                      i32.const 1
                      i32.add
                      local.set 5
                      local.get 13
                      local.set 3
                      block  ;; label = @10
                        block  ;; label = @11
                          loop  ;; label = @12
                            local.get 2
                            i32.const 2
                            i32.add
                            i32.const 16
                            i32.ge_u
                            br_if 1 (;@11;)
                            local.get 3
                            local.get 3
                            i32.const 4
                            i32.add
                            local.tee 3
                            i32.load
                            i32.store
                            local.get 2
                            i32.const 1
                            i32.add
                            local.tee 2
                            local.get 18
                            i32.lt_u
                            br_if 0 (;@12;)
                          end
                          local.get 5
                          i32.const 16
                          i32.ge_u
                          br_if 1 (;@10;)
                          local.get 5
                          i32.const 2
                          i32.shl
                          local.tee 3
                          local.get 1
                          i32.const 192
                          i32.add
                          i32.add
                          local.get 22
                          i32.store
                          local.get 1
                          i32.const -64
                          i32.sub
                          local.get 3
                          i32.add
                          local.tee 17
                          i32.load
                          local.tee 2
                          local.get 18
                          i32.le_s
                          br_if 6 (;@5;)
                          local.get 13
                          i32.load
                          local.set 6
                          local.get 5
                          local.set 18
                          local.get 4
                          local.set 22
                          i32.const 1
                          local.set 2
                          br 4 (;@7;)
                        end
                        i32.const 1049108
                        local.get 2
                        i32.const 2
                        i32.add
                        call 3
                        unreachable
                      end
                      i32.const 1049124
                      local.get 5
                      call 3
                      unreachable
                    end
                    i32.const 2
                    local.set 5
                    i32.const 1
                    local.set 2
                    br 4 (;@4;)
                  end
                  i32.const 0
                  local.set 2
                  br 0 (;@7;)
                end
                unreachable
              end
              i32.const 1049092
              local.get 10
              call 3
              unreachable
            end
            local.get 9
            i32.const 1
            i32.add
            local.set 9
            local.get 17
            local.get 2
            i32.const 1
            i32.add
            i32.store
            block  ;; label = @5
              block  ;; label = @6
                local.get 1
                i32.load offset=192
                local.tee 6
                i32.const 1
                i32.ge_s
                if  ;; label = @7
                  i32.const 1
                  local.set 5
                  br 1 (;@6;)
                end
                i32.const 2
                local.set 5
                br 1 (;@5;)
              end
              i32.const 1
              local.set 2
              br 1 (;@4;)
            end
            i32.const 1
            local.set 2
            br 0 (;@4;)
          end
          unreachable
        end
        unreachable
      end
      i32.const 1049212
      local.get 0
      call 3
      unreachable
    end
    i32.const 1049196
    local.get 2
    call 3
    unreachable)
  (table (;0;) 4 4 funcref)
  (memory (;0;) 17)
  (global (;0;) (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1049244))
  (global (;2;) i32 (i32.const 1049244))
  (export "memory" (memory 0))
  (export "__heap_base" (global 1))
  (export "__data_end" (global 2))
  (export "run_fannkuch" (func 10))
  (elem (;0;) (i32.const 1) 4 7 8)
  (data (;0;) (i32.const 1048576) "src/lib.rs\00\00\00\00\00\00attempt to divide by zero\00\00\00\00\00\00\00attempt to divide with overflow\00index out of bounds: the len is  but the index is 00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899called `Option::unwrap()` on a `None` valuesrc/libcore/option.rssrc/lib.rs")
  (data (;1;) (i32.const 1048982) "\10\00\0a\00\00\00%\00\00\00\1d\00\00\00\10\00\10\00\19\00\00\00\00\00\10\00\0a\00\00\00&\00\00\00\15\00\00\000\00\10\00\1f\00\00\00\00\00\10\00\0a\00\00\00&\00\00\00\15\00\00\00\00\00\10\00\0a\00\00\00.\00\00\00\15\00\00\00\00\00\10\00\0a\00\00\000\00\00\00\15\00\00\00\00\00\10\00\0a\00\00\00-\00\00\00\11\00\00\00\00\00\10\00\0a\00\00\00E\00\00\00\17\00\00\00\00\00\10\00\0a\00\00\00q\00\00\00\22\00\00\00\00\00\10\00\0a\00\00\00s\00\00\00\11\00\00\00P\00\10\00 \00\00\00p\00\10\00\12\00\00\00\02\00\00\00\00\00\00\00\01\00\00\00\03\00\00\00J\01\10\00+\00\00\00u\01\10\00\15\00\00\00Y\01\00\00\15\00\00\00\8a\01\10\00\0a\00\00\00\08\00\00\00\09\00\00\00\8a\01\10\00\0a\00\00\00\0a\00\00\00\14"))
