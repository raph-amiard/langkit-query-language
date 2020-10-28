import liblkqllang
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory
from prompt_toolkit.lexers import Lexer
from prompt_toolkit.styles.named_colors import NAMED_COLORS

ctx = liblkqllang.AnalysisContext()

class LKQLLexer(Lexer):
    def lex_document(self, document):
        colors = list(sorted(NAMED_COLORS, key=NAMED_COLORS.get))

        full_doc = "\n".join(document.lines)
        tmp_unit = ctx.get_from_buffer('<tmp_unit>', full_doc)
        tokens = [[] for _ in range(tmp_unit.root.sloc_range.end.line)]

        for tok in tmp_unit.root.tokens:
            tokens[tok.sloc_range.start.line - 1].append(tok)

        def get_line(lineno):
            return [
                (NAMED_COLORS['Red'] if tok.kind != 'Identifier' else NAMED_COLORS['Black'], tok.text)
                for tok in tokens[lineno]
            ]

        return get_line


if __name__ == '__main__':
    our_history = FileHistory(".example-history-file")
    session = PromptSession(history=our_history, lexer=LKQLLexer())

    dummy_unit = ctx.get_from_buffer('<dummy>', '12')
    dummy_unit.root.p_interp_init_from_project(
        'testsuite/ada_projects/deep_library/prj.gpr'
    )

    while True:
        cmd = session.prompt('> ')
        if cmd == 'exit':
            break

        cmd_unit = ctx.get_from_buffer('<repl_input>', cmd)
        print(cmd_unit.root.p_interp_eval)
