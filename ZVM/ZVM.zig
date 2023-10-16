const std = @import("std");

const memory_size = 1024;

pub const ZVM = struct {
    hlt: bool = false,
    memory: [memory_size]u8 = undefined,
    ip: usize = 0,
    sp: usize = 500,

    const Architecture = struct {
        
    };

    const Target = struct {
        const FlatBinary = Target {};
        
    };

    const Binary = struct {

    };
    
    const Instruction = enum(u8) {
        NOP,
        HLT,
        PUSH,
        POP,
        INC,
        DEC,
        DUP,
        SWAP,
        JMP_IF,
        PRINT_DEBUG,
    };

    const Exception = error {
        OK,
        ILLEGAL_INST,
        ILLEGAL_OPERAND,
    };

    fn DumpStack(self: ZVM) void {
        var i: usize = 500;
        std.debug.print("####################\n", .{});
        while (i < self.sp) {
            std.debug.print("{}\n", .{self.memory[i]});
            i += 1;
        }
        std.debug.print("####################\n\n", .{});
    }

    fn ExecuteInstruction(self: *ZVM) Exception {
        var inst: Instruction = @enumFromInt(self.memory[self.ip]);

        var err = switch (inst) {
            Instruction.NOP => {
                self.ip += 1;
                return Exception.OK;
            },
            Instruction.HLT => {
                self.hlt = true;
                return Exception.OK;
            },
            Instruction.PUSH => {
                self.memory[self.sp] = self.memory[self.ip + 1];
                self.sp += 1;
                self.ip += 2;
                return Exception.OK;
            },
            Instruction.POP => {
                self.sp -= 1;
                self.ip += 1;
                return Exception.OK;
            },
            Instruction.INC => {
                self.memory[self.sp - 1] += 1;
                self.ip += 1;
                return Exception.OK;
            },
            Instruction.DEC => {
                self.memory[self.sp - 1] -= 1;
                self.ip += 1;
                return Exception.OK;
            },
            Instruction.DUP => {
                self.memory[self.sp] = self.memory[self.sp - 1 - self.memory[self.ip + 1]];
                self.sp += 1;
                self.ip += 2;
                return Exception.OK;
            },
            Instruction.SWAP => {
                var tmp = self.memory[self.sp - 1 - self.memory[self.ip + 1]];

                self.memory[self.sp - 1 - self.memory[self.ip + 1]] =
                    self.memory[self.sp - 2 - self.memory[self.ip + 1]];

                self.memory[self.sp - 2 - self.memory[self.ip + 1]] = tmp;
                self.ip += 2;
                return Exception.OK;
            },
            Instruction.JMP_IF => {
                if (self.memory[self.sp - 1] != 0) {
                    self.sp -= 1;
                    self.ip = self.memory[self.ip + 1];
                } else {
                    self.ip += 2;
                }

                return Exception.OK;
            },
            Instruction.PRINT_DEBUG => {
                self.sp -= 1;
                self.ip += 1;
                std.debug.print("{}\n", .{self.memory[self.sp]});
                return Exception.OK;
            },
        };

        return err;
    }

    fn Run(self: *ZVM) Exception {
        while (!self.hlt) {
            var err = self.ExecuteInstruction();

            if (err != Exception.OK) {
                return err;
            }
        }

        return Exception.OK;
    }

    fn LoadProgramFromMemory(self: *ZVM, program: []u8) void {
        for (program, 0..) |inst, i| {
            self.memory[i] = inst;
        }
    }

    fn Debug(self: *ZVM) Exception {
        while (!self.hlt) {
            var lastInst: u8 = self.memory[self.ip];
            var inst: Instruction = @enumFromInt(lastInst);
            var name = @tagName(inst);
            std.debug.print("Inst: {s}\n", .{name});
            var err = self.ExecuteInstruction();
            self.DumpStack();

            if (err != Exception.OK) {
                return err;
            }
        }

        return Exception.OK;
    }

    fn Compile(self: *ZVM, target: Target) Binary {
        _ = target;
        _ = self;
    }
};