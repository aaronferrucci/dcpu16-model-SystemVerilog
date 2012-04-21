
`include "dcpu16_model.svh"
class dcpu16_model;

  u16 pc;
  u16 instruction;
  u16 sp;
  u16 ov;
  u16 unused;
  u16 regs[] = new[8];
  u16 mem[] = new[65536];
  event illegal_opcode;
  event illegal_operand;

  function u16 get_operand_value(t_operand operand);
    u16 value;
    begin
      // $display("get_operand_value(0x%0x)", operand);
      casez (operand)
        6'b000???: value = this.regs[operand];
        6'b001???: value = this.mem[this.regs[operand & 7]];
        6'b010???: value = this.mem[this.pc++ + this.regs[operand & 7]];
        6'h18: value = this.mem[this.sp++];
        6'h19: value = this.mem[this.sp];
        6'h1A: value = this.mem[--this.sp];
        6'h1B: value = this.sp;
        6'h1C: value = this.pc;
        6'h1D: value = this.ov;
        6'h1E: value = this.mem[this.mem[this.pc++]];
        6'h1F: value = this.mem[this.pc++];
        6'b1?????: value = operand & ~(6'h20);
        default: begin
          -> illegal_operand;
        end
      endcase
      return value;
    end
  endfunction

  function int skip_amount(t_operand operand);
    int skip;
    begin
      case (operand)
        6'b010???, 6'h1E, 6'h1F: skip = 1;
        default: skip = 0;
      endcase
    end
    return skip;
  endfunction

  task write_result(
      input t_operand dest,
      input u16 result,
      input u16 wr_pc,
      input u16 wr_sp
    );
    begin
      // $display("write_result(dest: 0x%0X, result: 0x%0X, wr_pc: 0x%0X, wr_sp: 0x%0X", dest, result, wr_pc, wr_sp);
      // This is deplorably-duplicated code from get_operand_value(). I'm not
      // seeing a way around it yet... maybe if I had pointers...
      casex (dest)
        6'b000???: this.regs[dest] = result;
        6'b001???: this.mem[this.regs[dest & 7]] = result;
        6'b010???: this.mem[wr_pc++ + this.regs[dest & 7]] = result;
        6'h18: this.mem[wr_sp++] = result;
        6'h19: this.mem[wr_sp] = result;
        6'h1A: this.mem[--wr_sp] = result;
        6'h1B: this.sp = result;
        6'h1C: this.pc = result;
        6'h1D: this.ov = result;
        6'h1E: this.mem[this.mem[wr_pc++]] = result;
        6'h1F: this.mem[wr_pc++] = result;
        6'b1?????: ; // nop, write-to-literal
        default: begin
          $display("illegal dest 0x%0X", dest);
          $stop;
        end
      endcase
    end
  endtask;

  task skip_next_instruction();
    begin
      // $display("skip_next_instruction start pc: 0x%0X", this.pc);
      // Skip over the instruction plus args - that could be 1, 2 or 3 words.
      this.instruction = this.mem[this.pc++];
      // Handle basic opcode operand 'b' or nonbasic opcode operand 'a'.
      this.pc += skip_amount(this.instruction[15:10]);

      // if basic opcode, handle operand 'a'
      if (this.instruction[3:0] != '0) begin
        // handle basic opcode's 'b' operand
        this.pc += skip_amount(this.instruction[9:4]);
      end

      // $display("skip_next_instruction end pc: 0x%0X", this.pc);
    end
  endtask

  task step();
    u16 result;
    t_basic_opcode basic_opcode;
    t_nonbasic_opcode nonbasic_opcode;
    t_operand a, b;
    u16 a_val, b_val;
    u16 wr_pc, wr_sp;
    begin
      this.instruction = this.mem[this.pc++];

      // Make a snapshot of pc, sp for write-result processing.
      wr_pc = this.pc;
      wr_sp = this.sp;

      if (this.instruction[3:0] == '0) begin
        // non-basic opcode
        {a, nonbasic_opcode} = this.instruction[15:4];
        a_val = get_operand_value(a);
        case (nonbasic_opcode)
          'h1: begin
            this.mem[--this.sp] = this.pc;
            this.pc = a_val;
          end
          default: begin
            -> illegal_opcode;
          end
        endcase
        // Nothing more to write, so we're done.
        return;
      end
      else begin
        // basic opcode
        {b, a, basic_opcode} = this.instruction;
        // $display("b: 0x%0X; a: 0x%0X; basic_opcode: 0x%0x", b, a, basic_opcode);
        a_val = get_operand_value(a);
        b_val = get_operand_value(b);
        // $display("b_val: 0x%0X; a_val: 0x%0X", b_val, a_val);
        case (basic_opcode)
          'h1: result = b_val;
          'h2: begin
            result = a_val + b_val;
            this.ov = result[15];
          end
          'h3: begin
            result = a_val - b_val;
            this.ov = result[15];
          end
          'h4: begin
            result = a_val * b_val;
            this.ov = result[15];
          end 
          'h5: begin
            if (b_val)
              result = a_val / b_val;
            else
              result = 0;
            this.ov = result[15];
          end
          'h6: begin
            if (b_val)
              result = a_val % b_val;
            else
              result = 0;
          end
          'h7: begin
            result = a_val << b_val;
            this.ov = result[15];
          end
          'h8: begin
            result = a_val >> b_val;
            this.ov = result[15];
          end
          'h9: result = a_val & b_val;
          'hA: result = a_val | b_val;
          'hB: result = a_val ^ b_val;
          'hC: begin
            if (a_val != b_val) skip_next_instruction;
            return;
          end
          'hD: begin
            if (a_val == b_val) skip_next_instruction;
            return;
          end
          'hE: begin
            if (a_val <= b_val) skip_next_instruction;
            return;
          end
          'hF: begin
            if (!(a_val & b_val)) skip_next_instruction;
            return;
          end
          default: begin
            -> illegal_opcode;
          end
        endcase

        // If we reach this point, result should have been assigned its
        // proper value; now write it back to the destination specified by
        // operand 'a'.
        write_result(a, result, wr_pc, wr_sp);
      end

    end
  endtask

  task dumpheader;
    begin
        $display("PC   SP   OV   A    B    C    X    Y    Z    I    J    Instruction");
        $display("---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -----------");
    end
  endtask

  function string disassemble();
    return "not implemented";
  endfunction

  task dumpstate;
    begin
        $display(
          "%04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %s",
          this.pc, this.sp, this.ov, 
          this.regs[0], this.regs[1], this.regs[2], this.regs[3], this.regs[4],
          this.regs[5], this.regs[6], this.regs[7], disassemble()
        );
    end
  endtask

  task load(input string filename);
    int i;
    begin
      $readmemh(filename, this.mem);
    end
  endtask

  task reset();
    int i;
    begin
      this.pc = '0;
      this.sp = '0;
      this.ov = '0;
      for (i = 0; i < this.regs.size; ++i)
        this.regs[i] = '0;
      for (i = 0; i < this.mem.size; ++i)
        this.mem[i] = 'x;
    end
  endtask

endclass

