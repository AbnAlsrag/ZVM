const std = @import("std");

const ZVM = struct {
    hlt: bool = false,
    target: Target,
    ip: u32,
    sp: u32,

    const ZASM = struct {
        machine: ZVM = undefined,
        path: []u8 = undefined,
        src: []u8 = undefined,

        fn ReadFile(self: *ZASM, path: []u8) void {
            _ = path;
            _ = self;
        }

        fn ParseFile(self: *ZASM) void {
            _ = self;
        }

        fn CompileZASM(self: *ZASM) void {
            _ = self;
        }
    };

    const Mode = enum(u8) {
        Bit8,
        Bit16,
        Bit32,
        Bit64,
    };

    const EmulationTarget = struct {
        registers: []u16,
        memory: []u8,
        
        ExecuteInstructionFN: fn (*EmulationTarget, *ZVM) Exception,

        fn ExecuteInstruction(self: *EmulationTarget, machine: *ZVM) Exception {
            return self.ExecuteInstructionFN(self, machine);
        }

        const X86 = struct {
            target: EmulationTarget,

            fn Init() X86 {
                return X86 { EmulationTarget { .ExecuteInstructionFN = X86.ExecuteInstruction } };
            }

            fn ExecuteInstruction(target: *EmulationTarget, machine: *ZVM) Exception {
                _ = machine;
                const self: X86 = @fieldParentPtr(X86, "target", target);
                _ = self;
                
            }
        };
    };

    const CompileTarget = struct {
        
    };

    const Target = struct {
        name: []u8,
        emulation: EmulationTarget,
        compiling: CompileTarget,

        const X86 = Target { .name = "X86", .emulation = EmulationTarget.X86, .compiling = undefined};
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
        PRINT_DEBUG,
        MOV,
        SYSCALL,
        CALL,
        RET,
        JMP,
        JMPZ,
        JMPNZ,
        CMP,
    };

    const Exception = error {
        OK,
        ILLEGAL_INST,
        ILLEGAL_OPERAND,
    };

    fn Init(self: *ZVM) void {
        _ = self;
    }

    fn DumpStack(self: ZVM) void {
        var i: usize = 500;
        std.debug.print("####################\n", .{});
        while (i < self.sp) {
            std.debug.print("{}\n", .{self.memory[i]});
            i += 1;
        }
        std.debug.print("####################\n\n", .{});
    }

    fn Run(self: *ZVM) Exception {
        while (!self.hlt) {
            var err = self.target.emulation.ExecuteInstruction(self);

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

    fn Compile(self: *ZVM) Binary {
        _ = self;
    }
};

pub fn main() !void {
    var machine: ZVM = ZVM{ .target = ZVM.Target.X86 };

    var program = [_]u8{
        @intFromEnum(ZVM.Instruction.PUSH), 0,
        @intFromEnum(ZVM.Instruction.PUSH), 13,
        @intFromEnum(ZVM.Instruction.SWAP), 0,
        @intFromEnum(ZVM.Instruction.DUP), 0,
        @intFromEnum(ZVM.Instruction.PRINT_DEBUG),
        @intFromEnum(ZVM.Instruction.INC),
        @intFromEnum(ZVM.Instruction.SWAP), 0,
        @intFromEnum(ZVM.Instruction.DEC),
        @intFromEnum(ZVM.Instruction.DUP), 0,
        @intFromEnum(ZVM.Instruction.JMPNZ), 4,
        @intFromEnum(ZVM.Instruction.POP),
        @intFromEnum(ZVM.Instruction.POP),
        @intFromEnum(ZVM.Instruction.HLT),
    };

    machine.LoadProgramFromMemory(&program);

    if (machine.Run() != ZVM.Exception.OK) {}

    var bin = machine.Compile(ZVM.Target.X86FlatBinary);
    _ = bin;
}