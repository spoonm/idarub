%include "ua.hpp"
%extend insn_t {
        op_t * ir_get_operand(int n) { return &self->Operands[n]; }
}
