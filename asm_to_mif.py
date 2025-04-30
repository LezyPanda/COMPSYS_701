import re
import sys

address_modes = {
    'inherent': '00',
    'immediate': '01',
    'direct': '10',
    'register': '11',
}

opcodes = {
    'LDR': '000000',
    'STR': '000010',
    'JMP': '011000',
    'PRESENT': '011100',
    'AND': '001000',
    'OR': '001100',
    'ADD': '111000',
    'SUB': '000100',
    'SUBV': '000011',
    'CLFZ': '010000',
    'CER': '111100',
    'CEOT': '111110',
    'SEOT': '111111',
    'NOOP': '110100',
    'SZ': '010100',
    'LER': '110110',
    'SSVOP': '111011',
    'SSOP': '111010',
    'LSIP': '110111',
    'DATACALL': '101000',
    'DATACALL2': '101001',
    'MAX': '011110',
    'STRPC': '011101',
    'SRES': '101010',
}

def parse_register(reg):
    if reg.startswith('R'):
        return int(reg[1:])
    return 0

def parse_immediate(val):
    if val.startswith('#'):
        return int(val[1:])
    return int(val)

def parse_line(line):
    line = line.split(';')[0].strip()
    if not line:
        return None
    if ':' in line:
        label, rest = line.split(':', 1)
        return ('label', label.strip(), rest.strip())
    tokens = line.split()
    if len(tokens) > 1 and tokens[0].isidentifier() and tokens[0].upper() not in opcodes:
        label = tokens[0]
        rest = ' '.join(tokens[1:])
        return ('label', label.strip(), rest.strip())
    return ('instr', line)

def detect_addr_mode(operand):
    if operand.startswith('#'):
        return 'immediate'
    elif operand.startswith('$'):
        return 'direct'
    elif operand.startswith('R'):
        return 'register'
    elif operand == '':
        return 'inherent'
    else:
        return 'direct'

def assemble_instruction(parts, labels, pc):
    mnemonic = parts[0].upper()
    opcode = opcodes.get(mnemonic, None)
    if opcode is None:
        raise Exception(f"Unknown opcode: {mnemonic}")
    am = 'inherent'
    rz = 0
    rx = 0
    operand = 0
    ops = parts[1:]
    ops = [o for o in ops if o]
    if mnemonic in ['NOOP', 'END', 'ENDPROG']:
        am = 'inherent'
    elif len(ops) == 1:
        am = detect_addr_mode(ops[0])
        if am == 'register':
            rz = parse_register(ops[0])
        elif am == 'immediate':
            operand = parse_immediate(ops[0])
        elif am == 'direct':
            key = ops[0][1:]
            operand = int(key) if key.isdigit() else labels.get(key, 0)
    elif len(ops) == 2:
        am = detect_addr_mode(ops[1])
        rz = parse_register(ops[0])
        if am == 'register':
            rx = parse_register(ops[1])
        elif am == 'immediate':
            operand = parse_immediate(ops[1])
        elif am == 'direct':
            key = ops[1][1:]
            operand = int(key) if key.isdigit() else labels.get(key, 0)
    elif len(ops) == 3:
        three_regs = ['ADD','SUB','SUBV','AND','OR']
        if mnemonic not in three_regs:
            raise Exception(f"Instruction {mnemonic} does not support three-register form")
        am = detect_addr_mode(ops[2])
        rz = parse_register(ops[0])
        if mnemonic in ['ADD','SUB','SUBV','AND','OR']:
            rx = parse_register(ops[2])
        else:
            rx = parse_register(ops[1])
        if am == 'immediate':
            operand = parse_immediate(ops[2])
        elif am == 'direct':
            key = ops[2][1:]
            operand = int(key) if key.isdigit() else labels.get(key, 0)
    am_bits = address_modes[am]
    instr = int(am_bits + opcode, 2)
    word1 = (instr << 8) | ((rz & 0xF) << 4) | (rx & 0xF)
    if am in ['immediate', 'direct']:
        word2 = operand & 0xFFFF
        return [word1, word2]
    else:
        return [word1]

def assemble(asm_lines):
    labels = {}
    pc = 0
    instructions = []
    for line in asm_lines:
        parsed = parse_line(line)
        if not parsed:
            continue
        if parsed[0] == 'label':
            label = parsed[1]
            # nah g
            if parsed[2].strip().upper() in ['ENDPROG', 'END']:
                labels[label] = pc
                continue
            labels[label] = pc
            if parsed[2]:
                instructions.append(parsed[2])
                pc += 1
        else:
            if parsed[1].strip().upper() in ['ENDPROG', 'END']:
                continue
            instructions.append(parsed[1])
            pc += 1
    mif_words = []
    pc = 0
    for line in instructions:
        if not line:
            continue
        parts = re.split(r'[\s,]+', line.strip())
        if not parts or not parts[0]:
            continue
        try:
            words = assemble_instruction(parts, labels, pc)
            mif_words.extend(words)
            pc += len(words)
        except Exception as e:
            print(f"Error at line: {line}\n{e}")
            sys.exit(1)
    return mif_words

def write_mif(words, filename, depth=4096, width=16):
    with open(filename, 'w') as f:
        f.write(f"WIDTH = {width};\n")
        f.write(f"DEPTH = {depth};\n\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = BIN;\n\n")
        f.write("CONTENT\n\tBEGIN\n")
        f.write(f"\t[00..{depth-1:03X}]: {'1'*width};\n")
        for addr, word in enumerate(words):
            f.write(f"\t{addr:X}\t:{word:0{width}b};\n")
        f.write("\tEND;\n")

def main():
    asm_file = 'ReCOP-ASM Package/test.asm'
    mif_file = 'modelsim/rawOutput.mif'
    mif_file2 = 'ReCOP (To be sorted)/rawOutput.mif'
    with open(asm_file, 'r', encoding='utf-8') as f:
        asm_lines = f.readlines()
    words = assemble(asm_lines)
    write_mif(words, mif_file)
    write_mif(words, mif_file2)

if __name__ == '__main__':
    main()

